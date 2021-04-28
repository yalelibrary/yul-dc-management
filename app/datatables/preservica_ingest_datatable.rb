# frozen_string_literal: true

class PreservicaIngestDatatable < AjaxDatatablesRails::ActiveRecord
  extend Forwardable

  def_delegators :@view, :link_to, :show_parent_preservica_ingest_path, :parent_object_path

  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||= {
      parent_oid: { source: "PreservicaIngest.parent_oid", orderable: true },
      child_oid: { source: "PreservicaIngest.child_oid", orderable: true },
      preservica_id: { source: "PreservicaIngest.preservica_id", orderable: true },
      batch_process_id: { source: "PreservicaIngest.batch_process_id", orderable: true },
      timestamp: { source: "PreservicaIngest.ingest_time", orderable: true }
    }
  end

  def data
    records.map do |preservica_ingest|
      {
        parent_oid: preservica_ingest.parent_oid,
        child_oid: preservica_ingest.child_oid,
        preservica_id: preservica_ingest.preservica_id,
        batch_process_id: preservica_ingest.batch_process_id,
        timestamp: preservica_ingest.ingest_time
      }
    end
  end

  def get_raw_records # rubocop:disable Naming/AccessorMethodName
    PreservicaIngest.all
  end
end
