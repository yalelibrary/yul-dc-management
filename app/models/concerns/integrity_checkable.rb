# frozen_string_literal: true

module IntegrityCheckable
  extend ActiveSupport::Concern

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Layout/LineLength
  def integrity_check
    self.admin_set = ''
    sets = admin_set

    child_objects_pool = ChildObject.joins(:parent_object).where.not(parent_object: { digital_object_source: 'Preservica' })

    child_object_sample = child_objects_pool.where(oid: child_objects_pool.ids.sample(2000))

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
            "Child Object: #{co.oid} - file exists but the file's checksum [#{Digest::SHA1.file(co.access_master_path)}] does not match what is saved on the child object [#{co.checksum}].", 'review-complete'
          )
        end
      else
        co.processing_event("Child Object: #{co.oid} - file not found at #{co.access_master_path} on #{ENV['ACCESS_MASTER_MOUNT']}.  Checksum could not be compared for the child object.",
'review-complete')
      end
      self.admin_set = split_sets.join(', ')
      save!

      co.parent_object.processing_event("Integrity check complete for Child Object: #{co.oid}", 'review-complete')
    end

    batch_processing_event("Integrity Check complete. #{child_object_sample.count} Child Object records reviewed.", "Complete")
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Layout/LineLength
end
