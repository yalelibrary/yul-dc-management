# frozen_string_literal: true

module DigitalObjectManagement
  extend ActiveSupport::Concern

  def generate_digital_object_json
    return nil unless authoritative_metadata_source && authoritative_metadata_source.metadata_cloud_name == "aspace"
    return nil unless ['Public', 'Yale Community Only'].include? visibility
    # create digital object from data and return JSON
    {   oid: oid,
        title: digital_object_title,
        thumbnailOid: representative_child && representative_child.oid || nil,
        thumbnailCaption: representative_child && representative_child.label || nil,
        archivesSpaceUri: aspace_uri,
        childCount: child_object_count }.to_json
  end

  def digital_object_title
    authoritative_json && authoritative_json["title"] && authoritative_json["title"][0]
  end

  def digital_object_check
    new_digital_object = generate_digital_object_json
    return unless digital_object_json != new_digital_object
    #  There has been a change that needs to be reported to metadata cloud
    send_digital_object_update(
      priorDigitalObject: digital_object_json.present? && JSON.parse(digital_object_json) || nil,
      digitalObject: new_digital_object.present? && JSON.parse(new_digital_object) || nil
    )
    ParentObject.update(oid, digital_object_json: new_digital_object)
  end

  def send_digital_object_update(digital_object_update)
    Rails.logger.info "\n\n\n\n\n*****************************************#{digital_object_update.to_json}\n*****************************************\n\n\n\n\n"
  end
end
