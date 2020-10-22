# frozen_string_literal: true

class BatchProcessDetailDatatable < AjaxDatatablesRails::ActiveRecord
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
      id: { },
      parent_oid: { source: "ParentObject.parent_id" },
      time: { },
      children: { source: "ParentObject.child_object_count" },
      status: {}
    }
  end

  def data
    # rubocop:disable Rails/OutputSafety
      records.map do |parent_object|
        {
          id: "ID",
          parent_oid: parent_object,
          time: "Time",
          children: parent_object.child_object_count,
          status: "TODO: Status",
        }
      end
    # rubocop:enable Rails/OutputSafety
  end

  def get_raw_records # rubocop:disable Naming/AccessorMethodName
    # insert query here
      BatchProcess.joins(:user).oids
  end
end

