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

  def batch_connections_for(_batch_process)
    raise 'Must be implemented'
  end

  def status_for_batch_process(batch_process)
    notes = notes_for_batch_process(batch_process)
    if notes.empty?
      "Pending"
    elsif finished_note(notes)
      "Complete"
    elsif latest_failures(batch_process).nil?
      "In progress - no failures"
    elsif latest_failures(batch_process)
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
      processing_event("The parent object was deleted", 'deleted')
    end
  end

  def latest_failures(batch_process)
    failures = note_records(batch_process).where(status: 'failed').order(:created_at)
    if failures.empty?
      nil
    else
      { reason: failures.pluck(:reason).join("\n\n"), time: failures.pluck(:created_at).join("\n\n") }
    end
  end

  def current_batch_connection
    @current_batch_connection ||= current_batch_process&.batch_connections&.find_or_create_by!(connectable: self)
  end

  def processing_event(message, status = 'info')
    unless current_batch_connection
      Rails.logger.warn(
        "[Statable] processing_event dropped (no batch connection): " \
        "#{self.class}##{try(:id) || try(:oid)} status=#{status} " \
        "current_bp=#{try(:current_batch_process)&.id.inspect} " \
        "last_batch_connection=#{try(:batch_connections)&.order(created_at: :desc)&.limit(1)&.pluck(:id, :batch_process_id).inspect} " \
        "message=#{message.to_s.truncate(200)} " \
        "caller=#{caller(1, 6).inspect}"
      )
      return "no batch connection"
    end
    IngestEvent.create!(
      status: status,
      reason: message,
      batch_connection: current_batch_connection
    )
    current_batch_connection&.update_status
  end
end
