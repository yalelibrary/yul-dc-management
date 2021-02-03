# frozen_string_literal: true

class BatchProcessDetailDatatable < AjaxDatatablesRails::ActiveRecord
  extend Forwardable

  def_delegators :@view, :link_to, :show_parent_batch_process_path

  def initialize(params, opts = {})
    @view = opts[:view_context]
    super
  end

  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||= {
      parent_oid: { source: 'BatchConnection.connectable_id', cond: :like, searchable: true },
      time: { source: 'BatchConnection.created_at', cond: :like, searchable: true },
      children: { source: 'ParentObject.child_object_count', cond: :like, searchable: true },
      status: { source: 'BatchConnection.status', cond: :like, searchable: true }
    }
  end

  def data
    # rubocop:disable Rails/OutputSafety
    records.map do |batch_connection|
      {
        parent_oid: link_to(batch_connection&.connectable_id, show_parent_batch_process_path(oid: batch_connection&.connectable_id.to_s)),
        time: batch_connection&.created_at,
        children: batch_connection.connectable&.child_object_count || 'pending, or parent deleted',
        status: batch_connection.status,
        DT_RowId: batch_connection&.connectable_id
      }
    end
    # rubocop:enable Rails/OutputSafety
  end

  def get_raw_records # rubocop:disable Naming/AccessorMethodName
    sql = "LEFT OUTER JOIN parent_objects ON batch_connections.connectable_id = parent_objects.oid AND batch_connections.connectable_type = 'ParentObject'"
    BatchConnection.joins(sql).where(batch_process_id: params[:id], connectable_type: "ParentObject")
  end
end
