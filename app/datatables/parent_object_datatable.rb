# frozen_string_literal: true

class ParentObjectDatatable < ApplicationDatatable
  extend Forwardable

  def_delegators :@view, :link_to, :parent_object_path, :edit_parent_object_path, :update_metadata_parent_object_path, :content_tag

  def initialize(params, opts = {})
    @view = opts[:view_context]
    @current_ability = opts[:current_ability]
    @set_keys = AdminSet.order(:key).distinct.pluck(:key)
    @set_labels = OpenWithPermission::PermissionSet.order(:label).distinct.pluck(:label)
    super
  end

  # rubocop:disable Metrics/MethodLength
  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||= {
      oid: { source: "ParentObject.oid", cond: :start_with, searchable: true, orderable: true },
      admin_set: { source: "AdminSet.key", cond: :string_eq, searchable: true, options: @set_keys, orderable: true },
      authoritative_source: { source: "MetadataSource.metadata_cloud_name", cond: :string_eq, searchable: true, options: MetadataSource.all_metadata_cloud_names, orderable: true },
      child_object_count: { source: "ParentObject.child_object_count", orderable: true },
      call_number: { source: "ParentObject.call_number", searchable: true, orderable: true },
      container_grouping: { source: "ParentObject.container_grouping", searchable: true, orderable: true },
      mms_id: { source: "ParentObject.mms_id", cond: :string_eq, searchable: true, orderable: true },
      alma_holding: { source: "ParentObject.alma_holding", cond: :string_eq, searchable: true, orderable: true },
      alma_item: { source: "ParentObject.alma_item", cond: :string_eq, searchable: true, orderable: true },
      bib: { source: "ParentObject.bib", cond: :string_eq, searchable: true, orderable: true },
      holding: { source: "ParentObject.holding", cond: :string_eq, searchable: true, orderable: true },
      item: { source: "ParentObject.item", cond: :string_eq, searchable: true, orderable: true },
      barcode: { source: "ParentObject.barcode", cond: :string_eq, searchable: true, orderable: true },
      aspace_uri: { source: "ParentObject.aspace_uri", cond: :like, searchable: true, orderable: true },
      digital_object_source: { source: "ParentObject.digital_object_source", cond: :like, searchable: true, options: ["None", "Preservica"], orderable: true },
      preservica_uri: { source: "ParentObject.preservica_uri", cond: :like, searchable: true, orderable: true },
      last_ladybird_update: { source: "ParentObject.last_ladybird_update", orderable: true },
      last_voyager_update: { source: "ParentObject.last_voyager_update", orderable: true },
      last_aspace_update: { source: "ParentObject.last_aspace_update", orderable: true },
      last_sierra_update: { source: "ParentObject.last_sierra_update", orderable: true },
      last_alma_update: { source: "ParentObject.last_alma_update", orderable: true },
      last_id_update: { source: "ParentObject.last_id_update", orderable: true },
      visibility: { source: "ParentObject.visibility", cond: :string_eq, searchable: true, options: ["Public", "Yale Community Only", "Private", "Open with Permission"], orderable: true },
      permission_set: { source: "OpenWithPermission::PermissionSet.label", cond: :string_eq, options: @set_labels, searchable: true, orderable: true },
      sensitive_materials: { source: "ParentObject.sensitive_materials", cond: :string_eq, searchable: true, options: ["Yes", "No"], orderable: true },
      extent_of_digitization: { source: "ParentObject.extent_of_digitization", cond: :string_eq, searchable: true, options: ["Completely digitized", "Partially digitized"], orderable: true },
      digitization_note: { source: "ParentObject.digitization_note", cond: :like, searchable: true, orderable: true },
      digitization_funding_source: { source: "ParentObject.digitization_funding_source", cond: :like, searchable: true, orderable: true },
      full_text: { source: "ParentObject.extent_of_full_text", searchable: true, orderable: true },
      project_identifier: { source: "ParentObject.project_identifier", searchable: true, orderable: true },
      created_at: { source: "ParentObject.created_at", searchable: true, orderable: true, cond: :start_with }
    }
  end
  # rubocop: enable Metrics/MethodLength

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Rails/OutputSafety,Metrics/MethodLength
  def data
    records.map do |parent_object|
      {
        oid: oid_column(parent_object).html_safe,
        admin_set: parent_object.admin_set.key,
        authoritative_source: parent_object.source_name,
        child_object_count: parent_object.child_object_count,
        call_number: parent_object.call_number,
        container_grouping: parent_object.container_grouping,
        mms_id: parent_object.mms_id,
        alma_holding: parent_object.alma_holding,
        alma_item: parent_object.alma_item,
        bib: parent_object.bib,
        holding: parent_object.holding,
        item: parent_object.item,
        barcode: parent_object.barcode,
        aspace_uri: parent_object.aspace_uri,
        digital_object_source: parent_object.digital_object_source,
        preservica_uri: parent_object.preservica_uri,
        last_ladybird_update: parent_object.last_ladybird_update,
        last_voyager_update: parent_object.last_voyager_update,
        last_aspace_update: parent_object.last_aspace_update,
        last_sierra_update: parent_object.last_sierra_update,
        last_alma_update: parent_object.last_alma_update,
        last_id_update: parent_object.last_id_update,
        visibility: parent_object.visibility,
        permission_set: parent_object&.permission_set&.label,
        sensitive_materials: parent_object&.sensitive_materials,
        extent_of_digitization: parent_object.extent_of_digitization,
        digitization_note: parent_object.digitization_note,
        digitization_funding_source: parent_object.digitization_funding_source,
        DT_RowId: parent_object.oid,
        full_text: parent_object.extent_of_full_text,
        project_identifier: parent_object.project_identifier,
        created_at: parent_object.created_at
      }
    end
  end
  # rubocop:enable Rails/OutputSafety,Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize

  def oid_column(parent_object)
    result = []
    result << link_to(parent_object.oid, parent_object_path(parent_object))
    result << with_icon('fa fa-pencil', edit_parent_object_path(parent_object)) if @current_ability.can? :edit, parent_object
    result << with_icon('fa fa-eye', parent_object.dl_show_url, target: :_blank)
    result.join(' ')
  end

  def with_icon(class_name, path, options = {})
    link_to(path, options) do
      content_tag(:i, '', class: class_name)
    end
  end

  def get_raw_records # rubocop:disable Naming/AccessorMethodName
    ParentObject.accessible_by(@current_ability, :read).joins(:authoritative_metadata_source, :admin_set).left_outer_joins(:permission_set).where("visibility != 'Redirect'")
  end
end
