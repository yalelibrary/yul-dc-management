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

  def mc_post(mc_url, data)
    metadata_cloud_username = ENV["MC_USER"]
    metadata_cloud_password = ENV["MC_PW"]
    HTTP.basic_auth(user: metadata_cloud_username, pass: metadata_cloud_password).post(mc_url, json: data)
  end

  def send_digital_object_update(digital_object_update)
    return unless ENV["VPN"] == "true"
    full_response = mc_post("https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/digital_object_updates", digital_object_update)
    case full_response.status
    when 200
      Rails.logger.info "Update sent successfully #{digital_object_update}"
    else
      Rails.logger.info "Error sending digital object update: #{full_response.status}, #{digital_object_update}"
    end
  rescue => e
    Rails.logger.info "Error sending digital object update: #{e}, #{digital_object_update}"
  end
end
