# frozen_string_literal: true
require 'csv'

class MetadataCloudService
  def mc_get(oid_url)
    metadata_cloud_username = ENV["MC_USER"]
    metadata_cloud_password = ENV["MC_PW"]
    HTTP.basic_auth(user: metadata_cloud_username, pass: metadata_cloud_password).get(oid_url)
  end

  def save_mc_json_to_file(mc_response)
    file_folder = Rails.root.join("spec", "fixtures", "new_json")
    json_metadata = mc_response.body.to_str
    JSON.parse(json_metadata)
    File.open(file_folder.join("test_file" + ".json"), "w")
  end

  def list_of_oids(oid_path)
    @list_of_oids ||= build_oid_array(oid_path)
  end

  def build_oid_array(oid_path)
    fixture_ids_table = CSV.read(oid_path, headers: true)
    fixture_ids_table.by_col[0]
  end

  def build_metadata_cloud_url(oid)
    "https://metadata-api-test.library.yale.edu/metadatacloud/api/ladybird/oid/#{oid}?mediaType=json"
  end

  def refresh_data(oid_path)
    list_of_oids(oid_path).each do |oid|
      mc_get(build_metadata_cloud_url(oid))
    end
  end
end
