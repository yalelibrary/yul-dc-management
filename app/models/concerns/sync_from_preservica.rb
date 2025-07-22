# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module SyncFromPreservica
  extend ActiveSupport::Concern

  # FETCHES CHILD OBJECTS FROM PRESERVICA
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def sync_from_preservica
    # byebug
    self.admin_set = ''
    sets = admin_set
    parsed_csv.each_with_index do |row, _index|
      begin
        parent_object = ParentObject.find(row['oid'])
        add_admin_set_to_bp(sets, parent_object)
        save!
      rescue
        batch_processing_event("Parent OID: #{row['oid']} not found in database", 'Skipped Import') if parent_object.nil?
        next
      end
      next unless validate_preservica_sync(parent_object, row)
      local_children_hash = {}
      parent_object.child_objects.each do |local_co|
        local_children_hash["hash_#{local_co.order}".to_sym] = { order: local_co.order,
                                                                 content_uri: local_co.preservica_content_object_uri,
                                                                 generation_uri: local_co.preservica_generation_uri,
                                                                 bitstream_uri: local_co.preservica_bitstream_uri,
                                                                 checksum: local_co.sha512_checksum }
      end
      begin
        preservica_children_hash = {}
        parent_preservica_uri = parent_object.preservica_uri.presence || row['preservica_uri'].presence || nil
        PreservicaImageService.new(parent_preservica_uri, parent_object.admin_set.key).image_list(parent_object.preservica_representation_type).each_with_index do |preservica_co, index|
          # increment by one so index lines up with order
          index_plus_one = index + 1
          preservica_children_hash["hash_#{index_plus_one}".to_sym] = { order: index_plus_one,
                                                                        content_uri: preservica_co[:preservica_content_object_uri],
                                                                        generation_uri: preservica_co[:preservica_generation_uri],
                                                                        bitstream_uri: preservica_co[:preservica_bitstream_uri],
                                                                        checksum: preservica_co[:sha512_checksum],
                                                                        bitstream: preservica_co[:bitstream] }
        end
      rescue PreservicaImageService::PreservicaImageServiceNetworkError => e
        batch_processing_event("Parent OID: #{row['oid']} because of #{e.message}", 'Skipped Import')
        raise
      rescue PreservicaImageService::PreservicaImageServiceError => e
        batch_processing_event("Parent OID: #{row['oid']} because of #{e.message}", 'Skipped Import')
        next
      end
      sync_images_preservica(local_children_hash, preservica_children_hash, parent_object)
    end
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity

  # SYNC IMAGES FROM PRESERVICA
  def sync_images_preservica(local_children_hash, preservica_children_hash, parent_object)
    # always update
    # if local_children_hash != preservica_children_hash
    setup_for_background_jobs(parent_object, parent_object.source_name)
    parent_object.sync_from_preservica(local_children_hash, preservica_children_hash)
    # else
    #   batch_processing_event("Child object count and order is the same.  No update needed.", "Skipped Row")
    # end
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  # ERROR HANDLING FOR PRESERVICA SYNC
  def validate_preservica_sync(parent_object, row)
    # byebug
    if parent_object.redirect_to.present?
      batch_processing_event("Parent OID: #{row['oid']} is a redirected parent object", 'Skipped Import')
      false
    elsif !current_ability.can?(:update, parent_object)
      batch_processing_event("Skipping row with parent oid: #{parent_object.oid}, user does not have permission to update", 'Permission Denied')
      false
    elsif parent_object.preservica_uri.nil? && row['preservica_uri'].nil?
      batch_processing_event("Parent OID: #{row['oid']} does not have a Preservica URI.  Please ensure Preservica URI is saved to parent or included in CSV.", 'Skipped Import')
      false
    elsif (parent_object.digital_object_source != 'Preservica' || parent_object.digital_object_source != 'preservica') && row['digital_object_source'].nil?
      batch_processing_event("Parent OID: #{row['oid']} does not have a Preservica digital object source.  Please ensure Digital Object Source is saved to parent or included in CSV.",
'Skipped Import')
      false
    elsif parent_object.preservica_representation_type.nil? && row['preservica_representation_type'].nil?
      batch_processing_event("Parent OID: #{row['oid']} does not have a Preservica representation type.  Please ensure Preservica representation type is saved to parent or included in CSV.",
'Skipped Import')
      false
    elsif !parent_object.admin_set.preservica_credentials_verified
      batch_processing_event("Admin set #{parent_object.admin_set.key} does not have Preservica credentials set", 'Skipped Import')
      false
    else
      true
    end
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
end
