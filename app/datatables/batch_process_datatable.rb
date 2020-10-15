# frozen_string_literal: true

class BatchProcessDatatable < AjaxDatatablesRails::ActiveRecord
  extend Forwardable

  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||= {
      process_id: { source: "BatchProcess.id" },
      user: { source: "BatchProcess.user_id" },
      # status: { source: "" },
      time: { source: "BatchProcess.created_at" },
      items: { source: "BatchProcess.oid" },
      status: {  },
      # duration: { source: "" },
      object_details: { }
    }
  end

  def data
    # rubocop:disable Rails/OutputSafety
    records.map do |batch_process|
      {
        process_id: batch_process.id,
        user: batch_process.user.uid,
        # status: batch_process.holding,
        time: batch_process.created_at,
        items: batch_process.oids.count,
        status: "TODO",
        object_details: "View(add link)"
        # DT_RowId: batch_process.id
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
