require 'forwardable'

class ParentObjectDatatable < AjaxDatatablesRails::ActiveRecord
  extend Forwardable

  # def_delegator :@view, :link_to
  # def_delegator :@view, :parent_objects_path

  def_delegators :@view, :link_to, :parent_objects_path

  def initialize(params, opts = {})
    @view = opts[:view_context]
    super
  end

  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||= {
      oid: { source: "ParentObject.oid", cond: :like },
      authoritative_source: { source: "MetadataSource.display_name", cond: :eq },
      bib: { source: "ParentObject.bib", cond: :like },
      holding: { source: "ParentObject.holding", cond: :like },
      item: { source: "ParentObject.item", cond: :like },
      barcode: { source: "ParentObject.barcode", cond: :like },
      aspace_uri: { source: "ParentObject.aspace_uri", cond: :like },
      last_ladybird_update: { source: "ParentObject.last_ladybird_update", cond: :like },
      last_voyager_update: { source: "ParentObject.last_voyager_update", cond: :like },
      last_aspace_update: { source: "ParentObject.last_aspace_update", cond: :like },
      last_id_update: { source: "ParentObject.last_id_update", cond: :like },
      visibility: { source: "ParentObject.visibility", cond: :like }
    }
  end

  def data
    records.map do |parent_object|
      {
        oid: link_to(parent_object.oid, parent_objects_path(parent_object)), remote: :true,
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
        DT_RowId: parent_object.oid
       }
    end
  end

  def get_raw_records
    ParentObject.joins(:authoritative_metadata_source)
  end

end
