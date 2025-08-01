# frozen_string_literal: true

class UpdateDigitalObjectsJob < ApplicationJob
  queue_as :metadata
  VOYAGER_AUTHORITATIVE_SOURCE_ID = 2

  def self.job_limit
    5000
  end

  # rubocop:disable Style/OptionalArguments
  # rubocop:disable Lint/UselessAssignment
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def perform(admin_set_id, start_position = 0)
    parent_objects = ParentObject.where(admin_set_id: admin_set_id, authoritative_metadata_source_id: VOYAGER_AUTHORITATIVE_SOURCE_ID)
                                 .order(:oid).offset(start_position)
                                 .limit(UpdateDigitalObjectsJob.job_limit)
    last_job = parent_objects.count < UpdateDigitalObjectsJob.job_limit
    return unless parent_objects.count.positive? # stop if nothing is found
    parent_objects.each do |po|
      # only force digital_object_check if a solr document is generated, or if it's private
      po.digital_object_check(true) if (po.to_solr.present? && po.child_object_count&.positive? && po.ready_for_manifest?) || po.visibility == 'Private'
    end
    UpdateDigitalObjectsJob.perform_later(admin_set_id, start_position + parent_objects.count) unless last_job
  end
  # rubocop:enable Style/OptionalArguments
  # rubocop:enable Lint/UselessAssignment
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
end

def push_pos(parent_objects)
  parent_objects.each do |po|
    # only force digital_object_check if a solr document is generated, or if it's private
    po.digital_object_check(true) if po.to_solr.present? && po.child_object_count&.positive? && po.ready_for_manifest?
  end
end
