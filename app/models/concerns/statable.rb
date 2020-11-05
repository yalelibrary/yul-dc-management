# frozen_string_literal: true

module Statable
  extend ActiveSupport::Concern
  def notes_for_batch_process(batch_process_id)
    note_records(batch_process_id).each_with_object({}) { |n, i| i[n.params[:status]] = n.created_at; }
  end

  def start_note(notes)
    @start_note ||= start_states.map { |state| notes[state] }.first
  end

  def finished_note(notes)
    @finished_note ||= finished_states.map { |state| notes[state] }.first
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
    elsif latest_failure(batch_process_id).nil?
      "In progress - no failures"
    elsif latest_failure(batch_process_id)
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

  def latest_failure(batch_process_id)
    failures = note_records(batch_process_id).where("params->>'status' = 'failed'")
      if failures.empty?
        nil
      else
        { reason: failures.last.params[:reason], time: failures.last[:created_at] }
      end
  end
end
