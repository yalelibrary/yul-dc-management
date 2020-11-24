# frozen_string_literal: true

class BatchProcessParentDatatable < AjaxDatatablesRails::ActiveRecord
  extend Forwardable

  def_delegators :@view, :link_to, :show_child_batch_process_path

  def initialize(params, opts = {})
    @view = opts[:view_context]
    @batch_process = opts[:batch_process]
    super
  end

  def view_columns
    @view_columns ||= {
      child_oid: { source: 'ChildObject.oid' },
      time: { source: 'ChildObject.created_at' },
      status: { source: '' }
    }
  end

  def data
    # rubocop:disable Rails/OutputSafety
    records.map do |child_object|
      {
        child_oid: link_to(child_object&.oid, show_child_batch_process_path(oid: child_object&.parent_object_oid, child_oid: child_object&.oid)),
        time: child_object&.created_at,
        status: child_object&.status_for_batch_process(@batch_process).to_s,
        DT_RowId: child_object&.oid
      }
    end
    # rubocop:enable Rails/OutputSafety
  end

  def get_raw_records # rubocop:disable Naming/AccessorMethodName
    ChildObject.where(parent_object_oid: params[:oid])
  end
end
