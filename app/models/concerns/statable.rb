# frozen_string_literal: true

module Statable
  extend ActiveSupport::Concern
  def notes_for_batch_process(batch_process_id)
    # The parameters passed in must be strings, or Postgres will get very angry
    note_records = Notification.where(["params->>'batch_process_id' = :id and
    params->>'parent_object_id' = :oid", { id: batch_process_id.to_s, oid:
    oid.to_s }])
    note_records.each_with_object({}) { |n, i| i[n.params[:status]] = n.created_at; }
  end

  def status_for_batch_process(batch_process_id)
    notes = notes_for_batch_process(batch_process_id)
    if notes["solr-indexed"]
      "Complete"
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
      start = notes["processing-queued"]
      finish = notes["solr-indexed"]
      finish - start if finish && start
    else
      "n/a"
    end
  end

  def note_records(batch_process_id)
    Notification.where(["params->>'batch_process_id' = :id and
    params->>'parent_object_id' = :oid", { id: batch_process_id.to_s, oid:
    oid.to_s }])
  end

  def failures_for_batch_process(batch_process_id)
    failures = []
    note_records(batch_process_id).each do |failure|
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
