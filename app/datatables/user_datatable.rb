# frozen_string_literal: true

class UserDatatable < AjaxDatatablesRails::ActiveRecord
  extend Forwardable

  def_delegators :@view, :link_to, :user_path, :edit_user_path

  def initialize(params, opts = {})
    @view = opts[:view_context]
    super
  end

  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||= {
      netid: { source: "User.uid", cond: :like, searchable: true, orderable: true },
      email: { source: "User.email", cond: :like, searchable: true, orderable: true },
      first_name: { source: "User.first_name", cond: :like, searchable: true, orderable: true },
      last_name: { source: "User.last_name", cond: :like, searchable: true, orderable: true },
      deactivated: { source: "User.deactivated", cond: :like, searchable: true, orderable: true, options: [{ value: true, label: "Inactive" }, { value: false, label: "Active", selected: true }] },
      actions: { source: "User.id", cond: :null_value, searchable: false, orderable: false }
    }
  end

  def data
    records.map do |user|
      {
        netid: link_to(user.uid, user_path(user)),
        email: user.email,
        first_name: user.first_name,
        last_name: user.last_name,
        deactivated: user.deactivated ? "Inactive" : "Active",
        actions: actions(user).html_safe # rubocop:disable Rails/OutputSafety
      }
    end
  end

  def actions(user)
    link_to('Edit', edit_user_path(user))
  end

  def get_raw_records # rubocop:disable Naming/AccessorMethodName
    User.all
  end
end
