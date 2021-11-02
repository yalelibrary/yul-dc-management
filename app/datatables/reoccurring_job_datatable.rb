# frozen_string_literal: true

class ReoccurringJobDatatable < AjaxDatatablesRails::ActiveRecord
  extend Forwardable

  def_delegators :@view, :link_to, :reoccurring_jobs_path

  def initialize(params, opts = {})
    @view = opts[:view_context]
    super
  end

  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||= {
      process_id: { source:  "ActivityStreamLog.id", cond: :eq, orderable: true },
      run_time: { source: "ActivityStreamLog.run_time", cond: :start_with, orderable: true },
      items: { source:  "ActivityStreamLog.activity_stream_items", cond: :like, orderable: true },
      status: { source:  "ActivityStreamLog.status", searchable: false, orderable: true },
      created: { source:  "ActivityStreamLog.created_at", searchable: false, orderable: true },
      updated: { source:  "ActivityStreamLog.updated_at", searchable: false, orderable: true },
      retrieved_records: { source:  "ActivityStreamLog.retrieved_records", orderable: true }
    }
  end

  def data
    # rubocop:disable Rails/OutputSafety
    records.map do |activity_stream|
      {
        process_id: activity_stream.id,
        run_time: activity_stream.run_time,
        items: activity_stream.activity_stream_items,
        status: activity_stream.status,
        created: activity_stream.created_at,
        updated: activity_stream.updated_at,
        retrieved_records: activity_stream.retrieved_records }
    end
    # rubocop:enable Rails/OutputSafety
  end

  def get_raw_records # rubocop:disable Naming/AccessorMethodName
   ActivityStreamLog.all
  end
end
