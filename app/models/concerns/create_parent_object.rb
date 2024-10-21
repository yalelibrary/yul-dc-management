# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module CreateParentObject
  extend ActiveSupport::Concern

  # CREATES PARENT OBJECTS FROM INGESTED CSV
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/BlockLength
  # rubocop:disable Layout/LineLength
  def create_new_parent_csv
    self.admin_set = ''
    sets = admin_set
    parsed_csv.each_with_index do |row, index|
      if row['digital_object_source'].present? && row['preservica_uri'].present? && !row['preservica_uri'].blank?
        begin
          parent_object = CsvRowParentService.new(row, index, current_ability, user).parent_object
          setup_for_background_jobs(parent_object, row['source'])
        rescue CsvRowParentService::BatchProcessingError => e
          batch_processing_event(e.message, e.kind)
          next
        rescue PreservicaImageService::PreservicaImageServiceError => e
          if e.message.include?("bad URI")
            batch_processing_event("The given URI does not match the URI of an entity in Preservica. Please make sure your URI is correct, starts with /structure-object/ or /information-object/, and includes no spaces or line breaks.", "Skipped Row")
            next
          else
            batch_processing_event("Skipping row [#{index + 2}] #{e.message}.", "Skipped Row")
            next
          end
        end
      else
        oid = row['oid']
        metadata_source = row['source']
        set = row['admin_set']

        if metadata_source.blank? && (set.present? && row.count > 2)
          batch_processing_event("Skipping row [#{index + 2}]. Source cannot be blank.", 'Skipped Row')
          next
        end
        model = row['parent_model'] || 'complex'
        admin_set = editable_admin_set(row['admin_set'], oid, index)
        next unless admin_set
        add_admin_set_to_bp(sets, admin_set)
        save!

        if oid.blank?
          oid = OidMinterService.generate_oids(1)[0]
          parent_object = ParentObject.new(oid: oid)
        else
          parent_object = ParentObject.find_or_initialize_by(oid: oid)
        end

        parent_object.aspace_uri = row['aspace_uri']
        parent_object.bib = row['bib']
        parent_object.holding = row['holding']
        parent_object.item = row['item']
        parent_object.digitization_note = row['digitization_note']
        parent_object.digitization_funding_source = row['digitization_funding_source']
        parent_object.rights_statement = row['rights_statement']

        if row['visibility'] == 'Open with Permission'
          permission_set = OpenWithPermission::PermissionSet.find_by(key: row['permission_set_key'])
          if permission_set.nil?
            batch_processing_event("Skipping row [#{index + 2}]. Process failed. Permission Set missing or nonexistent.", 'Skipped Row')
            next
          elsif user.has_role?(:administrator, permission_set) || user.has_role?(:sysadmin)
            parent_object.visibility = row['visibility']
            parent_object.permission_set_id = permission_set.id
          else
            batch_processing_event("Skipping row [#{index + 2}] because user does not have edit permissions for this Permission Set: #{permission_set.key}", 'Permission Denied')
            next
          end
        end

        if ParentObject.viewing_directions.include?(row['viewing_direction'])
          parent_object.viewing_direction = row['viewing_direction']
        else
          batch_processing_event("Parent #{oid} did not update value for Viewing Directions. Value: #{row['viewing_direction']} is invalid. For field Viewing Direction please use: left-to-right, right-to-left, top-to-bottom, bottom-to-top, or leave column empty", 'Invalid Vocabulary')
        end

        if ParentObject.viewing_hints.include?(row['display_layout'])
          parent_object.display_layout = row['display_layout']
        else
          batch_processing_event("Parent #{oid} did not update value for Display Layout. Value: #{row['display_layout']} is invalid. For field Display Layout / Viewing Hint please use: individuals, paged, continuous, or leave column empty", 'Invalid Vocabulary')
        end

        if metadata_source == 'aspace' && row['extent_of_digitization'].blank?
          batch_processing_event("Skipping row [#{index + 2}] with parent oid: #{oid}.  Parent objects with ASpace as a source must have an Extent of Digitization value.", 'Skipped Row')
          next
        elsif metadata_source == 'aspace' && row['extent_of_digitization'].present?
          if ParentObject.extent_of_digitizations.include?(row['extent_of_digitization'])
            parent_object.extent_of_digitization = row['extent_of_digitization']
          else
            batch_processing_event("Skipping row [#{index + 2}] with parent oid: #{oid}.  Extent of Digitization value must be 'Completely digitized' or 'Partially digitized'.", 'Skipped Row')
            next
          end
        end

        # Only runs on newly created parent objects
        unless parent_object.new_record?
          batch_processing_event("Skipping row [#{index + 2}] with existing parent oid: #{oid}", 'Skipped Row')
          next
        end

        parent_object.parent_model = model
        setup_for_background_jobs(parent_object, metadata_source)
        parent_object.admin_set = admin_set
        # TODO: enable edit action when added to batch actions
      end
      begin
        parent_object.save!
      rescue StandardError => e
        batch_processing_event("Skipping row [#{index + 2}] Unable to save parent: #{e.message}.", "Skipped Row")
      end
    end
  end
  # rubocop:enable Layout/LineLength
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/BlockLength

  # CHECKS TO SEE IF USER HAS ABILITY TO EDIT AN ADMIN SET:
  def editable_admin_set(admin_set_key, oid, index)
    admin_sets_hash = {}
    admin_sets_hash[admin_set_key] ||= AdminSet.find_by(key: admin_set_key)
    admin_set = admin_sets_hash[admin_set_key]
    if admin_set.blank?
      batch_processing_event("The admin set code is missing or incorrect. Please ensure an admin_set value is in the correct spreadsheet column and that your 3 or 4 letter code is correct.",
'Skipped Row')
      false
    elsif !current_ability.can?(:add_member, admin_set)
      batch_processing_event("Skipping row [#{index + 2}] because #{user.uid} does not have permission to create or update parent: #{oid}", 'Permission Denied')
      false
    else
      admin_set
    end
  end
end
