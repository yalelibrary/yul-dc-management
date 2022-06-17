# frozen_string_literal: true

module DigitalObjectManagement
  extend ActiveSupport::Concern

  def digital_object_json_available?
    return false unless child_object_count&.positive?
    return false unless authoritative_metadata_source && authoritative_metadata_source.metadata_cloud_name == "aspace"
    return false unless ['Public', 'Yale Community Only', 'Private'].include? visibility
    return false unless digital_object_title
    return false if redirect_to.present?
    true
  end

  def generate_digital_object_json
    return nil unless digital_object_json_available?
    # create digital object from data and return JSON
    {   oid: oid,
        title: digital_object_title,
        thumbnailOid: representative_child && representative_child.oid || nil,
        thumbnailCaption: representative_child && representative_child.label || nil,
        archivesSpaceUri: aspace_uri,
        childCount: child_object_count,
        visibility: visibility }.to_json
  end

  def digital_object_title
    authoritative_json && authoritative_json["title"] && authoritative_json["title"][0]
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def digital_object_check
    new_digital_object = generate_digital_object_json
    return unless (digital_object_json && digital_object_json.json || nil) != new_digital_object
    #  There has been a change that needs to be reported to metadata cloud
    if send_digital_object_update(
      priorDigitalObject: digital_object_json&.json.present? && JSON.parse(digital_object_json.json) || nil,
      digitalObject: new_digital_object.present? && JSON.parse(new_digital_object) || nil
    )
      # Only update the database is the update was sent to MC successfully.
      # This will cause unsuccessful sends to MC to be resent when the ParentObject is next updated.
      apply_new_digital_object_json(new_digital_object)
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

  def digital_object_delete
    unless digital_object_json&.json
      digital_object_json&.delete
      return
    end
    if send_digital_object_update(
      priorDigitalObject: JSON.parse(digital_object_json.json),
      digitalObject: nil
    )
      digital_object_json.delete
    end
  end

  def apply_new_digital_object_json(json)
    self.digital_object_json = DigitalObjectJson.new if digital_object_json.nil?
    digital_object_json.json = json
    digital_object_json.save
  end

  def mc_post(mc_url, data)
    metadata_cloud_username = ENV["MC_USER"]
    metadata_cloud_password = ENV["MC_PW"]
    HTTP.basic_auth(user: metadata_cloud_username, pass: metadata_cloud_password).post(mc_url, json: data)
  end

  def send_digital_object_update(digital_object_update)
    return false unless ENV["VPN"] == "true" && ENV["FEATURE_FLAGS"]&.include?("|DO-SEND|")
    full_response = mc_post("https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/digital_object_updates", digital_object_update)
    case full_response.status
    when 200
      Rails.logger.info "Update sent successfully #{digital_object_update}"
      return true
    else
      Rails.logger.info "Error sending digital object update: #{full_response.status}, #{digital_object_update}"
    end
    false
  rescue => e
    Rails.logger.info "Error sending digital object update: #{e}, #{digital_object_update}"
    false
  end
end
