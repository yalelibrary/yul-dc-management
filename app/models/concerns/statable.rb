# frozen_string_literal: true

module Statable
  extend ActiveSupport::Concern
  def notes_for_batch_process(batch_process)
    events_for_batch_process(batch_process).each_with_object({}) { |e, i| i[e.status] = e.created_at }
  end

  def events_for_batch_process(batch_process)
    IngestEvent.where(batch_connection: batch_connections_for(batch_process))
  end

  def start_note(notes)
    @start_note ||= start_states.map { |state| notes[state] }.compact.first
  end

  def finished_note(notes)
    @finished_note ||= finished_states.map { |state| notes[state] }.compact.first
  end

  def deleted_note(notes)
    notes["parent-deleted"]
  end

  def batch_connections_for(_batch_process)
    raise 'Must be implemented'
  end

  def status_for_batch_process(batch_process)
    notes = notes_for_batch_process(batch_process)
    if notes.empty?
      "Pending"
    elsif deleted_note(notes)
      "Parent object deleted"
    elsif finished_note(notes)
      "Complete"
    elsif latest_failure(batch_process).nil?
      "In progress - no failures"
    elsif latest_failure(batch_process)
      "Failed"
    else
      "Unknown status"
    end
  end

  def duration_for_batch_process(batch_process)
    notes = notes_for_batch_process(batch_process)
    if notes.present?
      start = start_note(notes)
      finish = finished_note(notes)
      finish - start if finish && start
    else
      "n/a"
    end
  end

  def note_records(batch_process)
    IngestEvent.where(batch_connection: batch_connections.where(batch_process: batch_process))
  end

  def note_deletion
    batch_connections.each do
      processing_event("The parent object was deleted", 'parent-deleted')
    end
  end

  def latest_failure(batch_process)
    failures = note_records(batch_process).where(status: 'failed')
    if failures.empty?
      nil
    else
      { reason: failures.last[:reason], time: failures.last[:created_at] }
    end
  end

  def current_batch_connection
    @current_batch_connection ||= current_batch_process&.batch_connections&.find_or_create_by(connectable: self)
  end

  def processing_event(message, status = 'info')
    return "no batch connection" unless current_batch_connection
    IngestEvent.create!(
      status: status,
      reason: message,
      batch_connection: current_batch_connection
    )
    current_batch_connection&.update_status!
  end
end
