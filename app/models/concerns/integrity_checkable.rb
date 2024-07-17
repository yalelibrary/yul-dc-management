# frozen_string_literal: true

module IntegrityCheckable
  extend ActiveSupport::Concern

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
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

        sets << ', ' + co.parent_object.admin_set.key
        split_sets = sets.split(',').uniq.reject(&:blank?)

        if co.access_master_exists?
          if co.access_master_checksum_matches?
            co.processing_event("Child Object: #{co.oid} - checksum matches and file exists.", 'review-complete')
          else
            co.processing_event(
              "Child Object: #{co.oid} - file exists but the file's checksum [#{Digest::SHA1.file(co.access_master_path)}] does not match what is saved on the child object [#{co.checksum}].", 'failed'
            )
          end
        else
          co.processing_event("Child Object: #{co.oid} - file not found at #{co.access_master_path} on #{ENV['ACCESS_MASTER_MOUNT']}.  Checksum could not be compared for the child object.",
  'failed')
        end
        self.admin_set = split_sets.join(', ')
        save!

        co.parent_object.processing_event("Integrity check complete for Child Object: #{co.oid}", 'review-complete')
      end
    rescue StandardError => e
      batch_processing_event("Integrity Check incomplete because of error: #{e.message}", 'Failed')
      raise
    end
    batch_processing_event("Integrity Check complete. #{child_object_sample.count} Child Object records reviewed.", "Complete")
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Layout/LineLength
end
