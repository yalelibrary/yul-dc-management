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
      user: { source: "User.uid", cond: :start_with, searchable: true, orderable: true },
      time: { source: "BatchProcess.created_at", cond: :like, searchable: true, orderable: true },
      size: { source: "BatchProcess.oid", searchable: false, orderable: false },
      status: { source: "BatchProcess.batch_status", searchable: false, orderable: false },
      object_details: { cond: :null_value, searchable: false, orderable: false }
    }
  end

  def data
    # rubocop:disable Rails/OutputSafety
    records.map do |batch_process|
      {
        process_id: link_to(batch_process.id, batch_process_path(batch_process)),
        user: batch_process.user.uid,
        time: batch_process.created_at,
        size: batch_process.oids&.count,
        status: batch_process.batch_status,
        object_details: link_to("View", batch_process_path(batch_process)),
        DT_RowId: batch_process.id
      }
    end
    # rubocop:enable Rails/OutputSafety
  end

  def get_raw_records # rubocop:disable Naming/AccessorMethodName
    BatchProcess.joins(:user)
  end
end
