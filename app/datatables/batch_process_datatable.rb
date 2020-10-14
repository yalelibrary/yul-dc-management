# frozen_string_literal: true

class BatchProcessDatatable < AjaxDatatablesRails::ActiveRecord
  extend Forwardable

  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||= {
      process_id: { source: "BatchProcess.id" }
      # user: { source: "BatchProcess.user_id" },
      # items: { source: "BatchProcess.oid" },
      # status: { source: "" },
      # start: { source: "BatchProcess.created_at" },
      # duration: { source: "" },
      # object_details: { source: "" }
    }
  end

  def data
    records.map do |batch_process|
      {
        process_id: batch_process.id,
        # user: batch_process.user.uid,
        # items: batch_process.oids.count,
        # status: batch_process.holding,
        # start: batch_process.created_at,
        # duration: batch_process.barcode,
        # object_details: batch_process.aspace_uri
        # DT_RowId: batch_process.id
      }
    end
  end

  def get_raw_records
    # insert query here
    # BatchProcess.all
    BatchProcess.joins(:user)
  end
end
