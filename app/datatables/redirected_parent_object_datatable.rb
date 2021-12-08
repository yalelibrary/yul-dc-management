# frozen_string_literal: true

class RedirectedParentObjectDatatable < AjaxDatatablesRails::ActiveRecord
  extend Forwardable

  def_delegators :@view, :link_to, :parent_object_path, :edit_parent_object_path, :content_tag

  def initialize(params, opts = {})
    @view = opts[:view_context]
    @current_ability = opts[:current_ability]
    @set_keys = AdminSet.order(:key).distinct.pluck(:key)
    super
  end

  # rubocop:disable Metrics/MethodLength
  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||= {
      oid: { source: "ParentObject.oid", cond: :start_with, searchable: true, orderable: true },
      admin_set: { source: "AdminSet.key", cond: :string_eq, searchable: true, options: @set_keys, orderable: true },
      authoritative_source: { source: "MetadataSource.metadata_cloud_name", cond: :string_eq, searchable: true, options: ["ladybird", "aspace", "ils"], orderable: true },
      updated_at: { source: "ParentObject.updated_at", orderable: true },
      visibility: { source: "ParentObject.visibility", cond: :string_eq, searchable: true, orderable: true },
      redirect_to: { source: "ParentObject.redirect_to", searchable: true, orderable: true }
    }
  end
  # rubocop: enable Metrics/MethodLength

  # rubocop:disable Rails/OutputSafety,Metrics/MethodLength
  def data
    records.map do |parent_object|
      {
        oid: oid_column(parent_object).html_safe,
        admin_set: parent_object.admin_set.key,
        authoritative_source: parent_object.source_name,
        updated_at: parent_object.updated_at,
        visibility: parent_object.visibility,
        DT_RowId: parent_object.oid,
        redirect_to: parent_object.redirect_to
      }
    end
  end
  # rubocop:enable Rails/OutputSafety,Metrics/MethodLength

  def oid_column(parent_object)
    result = []
    result << link_to(parent_object.oid, parent_object_path(parent_object))
    result << with_icon('fa fa-pencil-alt', edit_parent_object_path(parent_object)) if @current_ability.can? :edit, parent_object
    result << with_icon('fa fa-eye', parent_object.dl_show_url, target: :_blank)
    result.join(' ')
  end

  def with_icon(class_name, path, options = {})
    link_to(path, options) do
      content_tag(:i, '', class: class_name)
    end
  end

  def get_raw_records # rubocop:disable Naming/AccessorMethodName
    ParentObject.accessible_by(@current_ability, :read).joins(:authoritative_metadata_source, :admin_set).where("redirect_to != ''")
  end
end
