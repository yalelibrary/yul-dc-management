# frozen_string_literal: true

module Statable
  extend ActiveSupport::Concern
  def notes_for_batch_process(batch_process_id)
    @notes_for_batch_process ||= note_records(batch_process_id).each_with_object({}) { |n, i| i[n.params[:status]] = n.created_at; }
  end

  def start_note(notes)
    start_states.map { |state| notes[state] }.first
  end

  def finished_note(notes)
    finished_states.map { |state| notes[state] }.first
  end

  def deleted_note(notes)
    notes["parent-deleted"]
  end

  def status_for_batch_process(batch_process_id)
    notes = notes_for_batch_process(batch_process_id)
    if notes.empty?
      "Pending"
    elsif finished_note(notes)
      "Complete"
    elsif deleted_note(notes)
      "Parent object deleted"
    elsif failures_for_batch_process(batch_process_id).nil?
      "In progress - no failures"
    elsif failures_for_batch_process(batch_process_id)
      "Failed"
    else
      "Unknown status"
    end
  end

  def duration_for_batch_process(batch_process_id)
    notes = notes_for_batch_process(batch_process_id)
    if notes
      start = start_note(notes)
      finish = finished_note(notes)
      finish - start if finish && start
    else
      "n/a"
    end
  end

  def note_records(batch_process_id)
    Notification.where(["params->>'batch_process_id' = :id and
    params->>'#{self.class.to_s.underscore}_id' = :oid", { id: batch_process_id.to_s, oid:
    oid.to_s }])
  end

  def note_deletion
    batch_connections.each do |batch_connection|
      processing_event("The parent object was deleted", 'parent-deleted', batch_connection.batch_process, batch_connection)
    end
  end

  def failures_for_batch_process(batch_process_id)
    @failures_for_batch_process ||= failures_to_hash(batch_process_id)
  end

  def failures_to_hash(batch_process_id)
    failures = []
    note_records(batch_process_id).map do |failure|
      next unless failure.params[:status] == "failed"
      failure_note = {}
      failure_note["reason"] = failure.params[:reason]
      failure_note["time"] = failure.created_at
      failures << failure_note
    end
    return nil if failures.empty?
    failures
  end
end
