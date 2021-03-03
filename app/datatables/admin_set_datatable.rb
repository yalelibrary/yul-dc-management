# frozen_string_literal: true

class AdminSetDatatable < AjaxDatatablesRails::ActiveRecord
  extend Forwardable

  def_delegators :@view, :link_to, :edit_admin_set_path, :show_admin_set_path

  def initialize(params, opts = {})
    @view = opts[:view_context]
    super
  end

  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||= {
      key: { source: "AdminSet.key", cond: :start_with, searchable: true, orderable: true },
      label: { source: "AdminSet.label", cond: :start_with, searchable: true, orderable: true },
      homepage: { source: "AdminSet.homepage", cond: :like, searchable: true, orderable: true },
      actions: { searchable: false, orderable: false }
    }
  end

  def data
    records.map do |admin_set|
      {
        key: admin_set.key,
        label: admin_set.label,
        homepage: link_to(admin_set.homepage, admin_set.homepage),
        actions: "#{link_to('Edit', edit_admin_set_path(admin_set))} / #{link_to('Show', admin_set)}".html_safe, # rubocop:disable Rails/OutputSafety
        DT_RowId: "admin_set_#{admin_set.id}"
      }
    end
  end

  def get_raw_records # rubocop:disable Naming/AccessorMethodName
    AdminSet.all
  end
end
