# frozen_string_literal: true

module IntegrityCheckable
  extend ActiveSupport::Concern

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Layout/LineLength
  def integrity_check
    self.admin_set = ''
    sets = admin_set

    random_parents = ParentObject.where.not(digital_object_source: 'Preservica').and(ParentObject.where.not(child_object_count: 0).and(ParentObject.where.not(child_object_count: nil))).limit(2000).order("RANDOM()")

    child_object_sample = []
    random_parents.each do |po|
      random_order = rand(po.child_object_count)
      child_object_sample << po.child_objects[random_order]
    end
    begin
      child_object_sample.each do |co|
        attach_item(co.parent_object)
        attach_item(co)

        add_admin_set_to_bp(sets, co)

        if co.access_primary_exists?
          if co&.checksum_matches?
            co.parent_object.processing_event("Integrity check complete for Child Object: #{co.oid}", 'review-complete')
            co.processing_event("Child Object: #{co.oid} - file exists and checksum matches.", 'review-complete')
          else
            co.parent_object.processing_event("Integrity check complete for Child Object: #{co.oid}", 'failed')
            co.processing_event("The Child Object: #{co.oid} - has a checksum mismatch. The checksum of the image file saved to this child oid does not match the checksum of the image file in the database. This may mean that the image has been corrupted. Please verify integrity of image for Child Object: #{co.oid} - by manually comparing the checksum values and update record as necessary.", 'failed')
          end
        else
          co.parent_object.processing_event("Integrity check complete for Child Object: #{co.oid}", 'failed')
          co.processing_event("Child Object: #{co.oid} - file not found at #{co.access_primary_path} on #{ENV['ACCESS_PRIMARY_MOUNT']}.", 'failed')
        end
        save!
      end
    rescue StandardError => e
      batch_processing_event("Integrity Check incomplete because of error: #{e.message}", 'Failed')
      raise
    end
    batch_processing_event("Integrity Check complete. #{child_object_sample.count} Child Object records reviewed.", "Complete")
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Layout/LineLength
end
