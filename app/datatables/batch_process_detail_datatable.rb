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
      parent_oid: { source: 'ParentObject.oid' },
      time: { source: 'ParentObject.created_at' },
      children: { source: 'ParentObject.child_object_count' },
      status: { orderable: false } # remove "orderable: false" once this column has a value
    }
  end

  def data
    # rubocop:disable Rails/OutputSafety
    records.map do |parent_object|
      {
        parent_oid: link_to(parent_object&.oid, show_parent_batch_process_path(oid: parent_object.oid.to_s)),
        time: parent_object&.created_at,
        children: parent_object&.child_object_count || '(deleted)',
        status: 'TODO: Status',
        DT_RowId: parent_object&.oid
      }
    end
    # rubocop:enable Rails/OutputSafety
  end

  def get_raw_records # rubocop:disable Naming/AccessorMethodName
    BatchProcess.find(params[:id]).parent_objects
  end
end
