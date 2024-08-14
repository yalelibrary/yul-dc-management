# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module UpdateFulltextStatus
  extend ActiveSupport::Concern

    # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def update_fulltext_status(offset = 0, limit = -1)
    job_oids = oids
    job_oids = job_oids.drop(offset) if offset&.positive?
    job_oids = job_oids.first(limit) if limit&.positive?
    self.admin_set = ''
    sets = admin_set
    job_oids.each_with_index do |parent_oid, index|
      parent_object = ParentObject.find_by(oid: parent_oid)
      if parent_object.nil?
        batch_processing_event("Skipping row [#{index + 2}] because unknown parent: #{parent_oid}", 'Unknown Parent')
      elsif current_ability.can?(:update, parent_object)
        attach_item(parent_object)

        sets << ', ' + AdminSet.find(parent_object.admin_set_id).key
        split_sets = sets.split(',').uniq.reject(&:blank?)
        self.admin_set = split_sets.join(', ')
        save!

        parent_object.child_objects.each { |co| attach_item(co) }
        parent_object.processing_event("Parent #{parent_object.oid} is being processed", 'processing-queued')
        parent_object.update_fulltext
        parent_object.processing_event("Parent #{parent_object.oid} has been updated", 'update-complete')
      else
        batch_processing_event("Skipping row [#{index + 2}] because #{user.uid} does not have permission to create or update parent: #{parent_oid}", 'Permission Denied')
      end
    end
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

end