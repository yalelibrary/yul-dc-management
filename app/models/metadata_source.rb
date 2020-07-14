# frozen_string_literal: true

class MetadataSource < ApplicationRecord

  def fetch_record(parent_object)
    mc_url = parent_object.send(url_type)
    full_response = mc_get(mc_url)
    return unless full_response.status == 200
    raw_metadata = full_response.body.to_str
    JSON.parse(raw_metadata)
  end

  def url_type
    case metadata_cloud_name
    when "ladybird"
      "ladybird_cloud_url"
    when "ils"
      "voyager_cloud_url"
    when "aspace"
      "aspace_cloud_url"
    end
  end

  def mc_get(mc_url)
    metadata_cloud_username = ENV["MC_USER"]
    metadata_cloud_password = ENV["MC_PW"]
    HTTP.basic_auth(user: metadata_cloud_username, pass: metadata_cloud_password).get(mc_url)
  end
end
