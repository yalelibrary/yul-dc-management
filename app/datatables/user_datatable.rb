# frozen_string_literal: true

class UserDatatable < AjaxDatatablesRails::ActiveRecord
  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||= {
      netid: { source: "User.uid", cond: :like, searchable: true, orderable: true },
      email: { source: "User.email", cond: :like, searchable: true, orderable: true },
      deactivated: { source: "User.deactivated", cond: :like, searchable: true, orderable: true, options: [{ value: true, label: "Inactive" }, { value: false, label: "Active", selected: true }] }
    }
  end

  def data
    records.map do |record|
      {
        netid: record.uid,
        email: record.email,
        deactivated: record.deactivated ? "Inactive" : "Active"
      }
    end
  end

  def get_raw_records # rubocop:disable Naming/AccessorMethodName
    User.all
  end
end
