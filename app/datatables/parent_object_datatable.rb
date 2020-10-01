# frozen_string_literal: true

class ParentObjectDatatable < AjaxDatatablesRails::ActiveRecord
  extend Forwardable

  def_delegators :@view, :link_to, :parent_object_path, :edit_parent_object_path, :update_metadata_parent_object_path

  def initialize(params, opts = {})
    @view = opts[:view_context]
    super
  end

  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||= {
      oid: { source: "ParentObject.oid", cond: :like },
      authoritative_source: { source: "MetadataSource.display_name", cond: :like, searchable: true },
      bib: { source: "ParentObject.bib", cond: :like, searchable: true },
      holding: { source: "ParentObject.holding", cond: :like, searchable: true },
      item: { source: "ParentObject.item", cond: :like, searchable: true },
      barcode: { source: "ParentObject.barcode", cond: :like, searchable: true },
      aspace_uri: { source: "ParentObject.aspace_uri", cond: :like },
      last_ladybird_update: { source: "ParentObject.last_ladybird_update", cond: :like },
      last_voyager_update: { source: "ParentObject.last_voyager_update", cond: :like },
      last_aspace_update: { source: "ParentObject.last_aspace_update", cond: :like },
      last_id_update: { source: "ParentObject.last_id_update", cond: :like },
      visibility: { source: "ParentObject.visibility", cond: :like, searchable: true },
      actions: { source: "ParentObject.oid", cond: :null_value, searchable: false, orderable: false }
    }
  end

  def data
    # rubocop:disable Rails/OutputSafety
    records.map do |parent_object|
      {
        oid: link_to(parent_object.oid, parent_object_path(parent_object)) + get_blacklight_parent_url(parent_object.oid).html_safe,
        authoritative_source: parent_object.source_name,
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
        actions: actions(parent_object).html_safe,
        DT_RowId: parent_object.oid
      }
    end
    # rubocop:enable Rails/OutputSafety
  end

  def actions(parent_object)
    "#{link_to('Edit', edit_parent_object_path(parent_object))}" \
      " | #{link_to('Update Metadata', update_metadata_parent_object_path(parent_object))}" \
      " | #{link_to('Destroy', parent_object_path(parent_object), method: :delete, data: { confirm: 'Are you sure?' })}"
  end

  def get_blacklight_parent_url(path)
    "<br> <a class='btn btn-info btn-sm' href='#{blacklight_url(path)}' target='_blank' > Discover</a>"
  end

  def blacklight_url(path)
    base = ENV['BLACKLIGHT_BASE_URL'] || 'localhost:3000'
    "#{base}/catalog/#{path}"
  end

  def get_raw_records # rubocop:disable Naming/AccessorMethodName
    ParentObject.joins(:authoritative_metadata_source)
  end
end
