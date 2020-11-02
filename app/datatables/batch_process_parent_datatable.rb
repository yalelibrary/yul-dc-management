# frozen_string_literal: true

class BatchProcessParentDatatable < AjaxDatatablesRails::ActiveRecord
  extend Forwardable

  # def_delegators :@view, :link_to, #:show_parent_batch_process_path

  # def initialize(params, opts = {})
  #   @view = opts[:view_context]
  #   super
  # end

  def view_columns
    @view_columns ||= {
      child_oid: { source: '', cond: :like, searchable: true },
      time: { source: '', cond: :like, searchable: true },
      status: { cond: :null_value, searchable: false, orderable: false }
    }
  end

  def data
    # rubocop:disable Rails/OutputSafety
    records.map do |parent_object|
      {
        child_oid: 'TODO',
        time: 'TODO',
        status: 'TODO',
        DT_RowId: 'TODO'
      }
    end
    # rubocop:enable Rails/OutputSafety
  end

  def get_raw_records # rubocop:disable Naming/AccessorMethodName
    # ParentObject.where(oid: params[:id])
  end
end
