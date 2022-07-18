# frozen_string_literal: true

class BatchProcessDatatable < AjaxDatatablesRails::ActiveRecord
  extend Forwardable

  def_delegators :@view, :link_to, :batch_process_path

  def initialize(params, opts = {})
    @view = opts[:view_context]
    super
  end

  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||= {
      process_id: { source: "BatchProcess.id", cond: :eq, searchable: true, orderable: true },
      admin_set: { source: "BatchProcess.admin_sets", cond: :start_with, searchable: true, orderable: true },
      user: { source: "User.uid", cond: :start_with, searchable: true, orderable: true },
      time: { source: "BatchProcess.created_at", cond: :like, orderable: true },
      size: { source: "BatchProcess.oid", searchable: false, orderable: false },
      status: { source: "BatchProcess.batch_status", searchable: false, orderable: false },
      batch_ingest_events_count: { source: "BatchProcess.batch_ingest_events_count", searchable: false, orderable: false },
      batch_action: { source: "BatchProcess.batch_action", searchable: true, orderable: true, options: BatchProcess.batch_actions }
    }
  end

  def data
    # rubocop:disable Rails/OutputSafety
    records.map do |batch_process|
      {
        process_id: link_to(batch_process.id, batch_process_path(batch_process)),
        admin_set: batch_process.admin_sets,
        user: batch_process.user.uid,
        time: batch_process.created_at,
        size: batch_process.oids&.count,
        status: batch_process.batch_status,
        batch_ingest_events_count: link_to(batch_process.batch_ingest_events_count, batch_process_path(batch_process),
                                           class: batch_process.batch_ingest_events_count.positive? ? "btn btn-warning" : ""),
        batch_action: batch_process.batch_action,
        DT_RowId: batch_process.id
      }
    end
    # rubocop:enable Rails/OutputSafety
  end

  def get_raw_records # rubocop:disable Naming/AccessorMethodName
    BatchProcess.joins(:user)
  end
end
