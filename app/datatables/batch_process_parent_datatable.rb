# frozen_string_literal: true

class BatchProcessParentDatatable < AjaxDatatablesRails::ActiveRecord
  extend Forwardable

  # def_delegators :@view, :link_to, #:show_parent_batch_process_path

  # def initialize(params, opts = {})
  #   @view = opts[:view_context]
  # super
  # end

  # TODO(alishaevn): determine the source for time and status
  def view_columns
    @view_columns ||= {
      child_oid: { source: 'ChildObject.oid' },
      time: { source: '' },
      status: { source: '' }
    }
  end

  # TODO(alishaevn): determine the method for time
  def data
    # rubocop:disable Rails/OutputSafety
    records.map do |child_object|
      {
        child_oid: child_object.oid,
        time: child_object.notes_for_batch_process(params[:id]),
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
