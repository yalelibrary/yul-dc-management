# frozen_string_literal: true

class PreservicaIngestDatatable < AjaxDatatablesRails::ActiveRecord
  extend Forwardable

  def_delegators :@view

  def initialize(params, opts = {})
    @view = opts[:view_context]
    @current_ability = opts[:current_ability]
    super
  end

  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||= {
      parent_oid: { source: "PreservicaIngest.parent_oid", searchable: true, orderable: true },
      child_oid: { source: "PreservicaIngest.child_oid", searchable: true, orderable: true },
      parent_preservica_id: { source: "PreservicaIngest.preservica_id", searchable: true, orderable: false },
      child_preservica_id: { source: "PreservicaIngest.preservica_id", searchable: true, orderable: false },
      batch_process_id: { source: "PreservicaIngest.batch_process_id", searchable: true, orderable: true },
      timestamp: { source: "PreservicaIngest.ingest_time", orderable: true }
    }
  end

  def data
    records.map do |preservica_ingest|
      {
        parent_oid: preservica_ingest.parent_oid,
        child_oid: preservica_ingest.child_oid,
        parent_preservica_id: preservica_ingest.preservica_id,
        child_preservica_id: preservica_ingest.preservica_child_id,
        batch_process_id: preservica_ingest.batch_process_id,
        timestamp: preservica_ingest.ingest_time
      }
    end
  end

  def get_raw_records # rubocop:disable Naming/AccessorMethodName
    PreservicaIngest.accessible_by(@current_ability, :read)
  end
end
