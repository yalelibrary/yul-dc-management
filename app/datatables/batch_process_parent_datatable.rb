# frozen_string_literal: true

class BatchProcessParentDatatable < AjaxDatatablesRails::ActiveRecord
  extend Forwardable

  # def_delegators :@view, :link_to, #:show_parent_batch_process_path

  # def initialize(params, opts = {})
  #   @view = opts[:view_context]
  # super
  # end

  def view_columns
    @view_columns ||= {
      child_oid: { source: 'ChildObject.oid' },
      time: { source: '', cond: :like, searchable: true, orderable: false },
      status: { cond: :null_value, searchable: false, orderable: false }
    }
  end

  def data
    # rubocop:disable Rails/OutputSafety
    records.map do |child_object|
      {
        child_oid: child_object.oid,
        time: 'TODO',
        status: child_object.present? ? child_object.status_for_batch_process(params[:id]).to_s : "#{params[:oid]} deleted",
        DT_RowId: child_object.oid
      }
    end
    # rubocop:enable Rails/OutputSafety
  end

  def get_raw_records # rubocop:disable Naming/AccessorMethodName
    ChildObject.where(parent_object_oid: params[:oid])
  end
end
