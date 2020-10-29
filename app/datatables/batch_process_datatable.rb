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
      process_id: { source: "BatchProcess.id", cond: :like, searchable: true },
      user: { source: "BatchProcess.user_id", cond: :like, searchable: true },
      time: { source: "BatchProcess.created_at", cond: :like, searchable: true },
      size: { source: "BatchProcess.oid", cond: :like, searchable: true },
      status: {},
      object_details: {}
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
        status: "TODO: Status",
        object_details: link_to("View", batch_process_path(batch_process)),
        DT_RowId: batch_process.id
      }
    end
    # rubocop:enable Rails/OutputSafety
  end

  def get_raw_records # rubocop:disable Naming/AccessorMethodName
    # insert query here
    # BatchProcess.all
    BatchProcess.joins(:user)
  end
end
