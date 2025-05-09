# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module RefreshMet
  extend ActiveSupport::Concern

  # METS METADATA CLOUD: ------------------------------------------------------------------------- #

  # MAKES CALL FOR UPDATED DATA
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Rails/SaveBang
  def refresh_metadata_cloud_mets
    metadata_source = mets_doc.metadata_source
    self.admin_set = ''
    sets = admin_set
    if ParentObject.exists?(oid: oid)
      batch_processing_event("Skipping mets import for existing parent: #{oid}", 'Skipped Import')
      return
    end
    ParentObject.create(oid: oid) do |parent_object|
      set_values_from_mets(parent_object, metadata_source)
      if parent_object.admin_set.present?
        add_admin_set_to_bp(sets, parent_object)
        save
      end
    end
    PreservicaIngest.create(parent_oid: oid, preservica_id: mets_doc.parent_uuid, batch_process_id: id, ingest_time: Time.current) unless mets_doc.parent_uuid.nil?
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Rails/SaveBang

  # SETS VALUES FROM METS METADATA
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def set_values_from_mets(parent_object, metadata_source)
    if metadata_source == 'alma'
      parent_object.mms_id = mets_doc.bib
      parent_object.alma_holding = mets_doc.holding
      parent_object.alma_item = mets_doc.item
    else
      parent_object.bib = mets_doc.bib
      parent_object.holding = mets_doc.holding
      parent_object.item = mets_doc.item
    end
    parent_object.barcode = mets_doc.barcode
    parent_object.visibility = mets_doc.visibility
    parent_object.rights_statement = mets_doc.rights_statement
    parent_object.viewing_direction = mets_doc.viewing_direction
    parent_object.display_layout = mets_doc.viewing_hint
    parent_object.aspace_uri = mets_doc.aspace_uri if mets_doc.valid_aspace?
    setup_for_background_jobs(parent_object, metadata_source)
    parent_object.from_mets = true
    parent_object.last_mets_update = Time.current
    parent_object.representative_child_oid = mets_doc.thumbnail_image
    parent_object.admin_set = mets_doc.admin_set
    parent_object.extent_of_digitization = mets_doc.extent_of_dig
    parent_object.digitization_note = mets_doc.dig_note
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
end
