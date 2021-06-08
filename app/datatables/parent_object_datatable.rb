# frozen_string_literal: true

class ParentObjectDatatable < AjaxDatatablesRails::ActiveRecord
  extend Forwardable

  def_delegators :@view, :link_to, :parent_object_path, :edit_parent_object_path, :update_metadata_parent_object_path, :content_tag

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
      child_object_count: { source: "ParentObject.child_object_count", orderable: true },
      bib: { source: "ParentObject.bib", cond: :string_eq, searchable: true, orderable: true },
      holding: { source: "ParentObject.holding", cond: :string_eq, searchable: true, orderable: true },
      item: { source: "ParentObject.item", cond: :string_eq, searchable: true, orderable: true },
      barcode: { source: "ParentObject.barcode", cond: :string_eq, searchable: true, orderable: true },
      aspace_uri: { source: "ParentObject.aspace_uri", cond: :like, searchable: true, orderable: true },
      last_ladybird_update: { source: "ParentObject.last_ladybird_update", orderable: true },
      last_voyager_update: { source: "ParentObject.last_voyager_update", orderable: true },
      last_aspace_update: { source: "ParentObject.last_aspace_update", orderable: true },
      last_id_update: { source: "ParentObject.last_id_update", orderable: true },
      visibility: { source: "ParentObject.visibility", cond: :string_eq, searchable: true, options: ["Public", "Yale Community Only", "Private"], orderable: true },
      extent_of_digitization: { source: "ParentObject.extent_of_digitization", orderable: true },
      digitization_note: { source: "ParentObject.digitization_note", orderable: true },
      actions: { source: "ParentObject.oid", cond: :null_value, searchable: false, orderable: false }
    }
  end
  # rubocop: enable Metrics/MethodLength

  # rubocop:disable Rails/OutputSafety,Metrics/MethodLength,Metrics/AbcSize
  def data
    records.map do |parent_object|
      {
        oid: link_to(parent_object.oid, parent_object_path(parent_object)) +
          (with_icon('fa fa-pencil-alt', edit_parent_object_path(parent_object)) if @current_ability.can? :edit, parent_object) +
          with_icon('fa fa-eye', parent_object.dl_show_url),
        admin_set: parent_object.admin_set.key,
        authoritative_source: parent_object.source_name,
        child_object_count: parent_object.child_object_count,
        bib: parent_object.bib,
        holding: parent_object.holding,
        item: parent_object.item,
        barcode: parent_object.barcode,
        aspace_uri: parent_object.aspace_uri,
        last_ladybird_update: parent_object.last_ladybird_update,
        last_voyager_update: parent_object.last_voyager_update,
        last_aspace_update: parent_object.last_aspace_update,
        last_id_update: parent_object.last_id_update,
        visibility: parent_object.visibility,
        extent_of_digitization: parent_object.extent_of_digitization,
        digitization_note: parent_object.digitization_note,
        actions: actions(parent_object).html_safe,
        DT_RowId: parent_object.oid
      }
    end
  end
  # rubocop:enable Rails/OutputSafety,Metrics/MethodLength

  def actions(parent_object)
    actions = []
    actions << with_icon('fa fa-trash', parent_object_path(parent_object), method: :delete, data: { confirm: 'Are you sure?' }) if @current_ability.can? :destroy, parent_object
    actions << link_to('Update Metadata', update_metadata_parent_object_path(parent_object), method: :post) if @current_ability.can? :update, parent_object
    actions.join('<br>')
  end

  def with_icon(class_name, path, options = {})
    link_to(content_tag(:i, '', class: class_name), path, options)
  end

  def get_raw_records # rubocop:disable Naming/AccessorMethodName
    ParentObject.accessible_by(@current_ability, :read).joins(:authoritative_metadata_source, :admin_set)
  end
end
