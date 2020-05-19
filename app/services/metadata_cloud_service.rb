# frozen_string_literal: true
require 'csv'

class MetadataCloudService
  ##
  # This is the method that is called from the yale:refresh_fixture_data rake task
  def self.refresh_fixture_data(oid_path)
    mcs = MetadataCloudService.new
    mcs.list_of_oids(oid_path).each do |oid|
      metadata_cloud_url = mcs.build_metadata_cloud_url(oid)
      full_response = mcs.mc_get(metadata_cloud_url)
      mcs.save_mc_json_to_file(full_response, oid)
    end
  end

  ##
  # Takes a Metadata Cloud formatted url and returns the full HTTP response with headers
  def mc_get(oid_url)
    metadata_cloud_username = ENV["MC_USER"]
    metadata_cloud_password = ENV["MC_PW"]
    HTTP.basic_auth(user: metadata_cloud_username, pass: metadata_cloud_password).get(oid_url)
  end

  ##
  # Takes a full HTTP response with headers and saves a json file
  def save_mc_json_to_file(mc_response, oid)
    file_folder = Rails.root.join("spec", "fixtures", "ladybird")
    raw_metadata = mc_response.body.to_str
    parsed_metadata = JSON.parse(raw_metadata)
    File.write(file_folder.join("oid-#{oid}" + ".json"), JSON.pretty_generate(parsed_metadata))
  end

  ##
  # Takes a csv file
  def list_of_oids(oid_path)
    @list_of_oids ||= build_oid_array(oid_path)
  end

  ##
  # Takes a csv file and returns an array containing the values from the first column
  def build_oid_array(oid_path)
    fixture_ids_table = CSV.read(oid_path, headers: true)
    fixture_ids_table.by_col[0]
  end

  def build_metadata_cloud_url(oid)
    "https://metadata-api-test.library.yale.edu/metadatacloud/api/ladybird/oid/#{oid}?mediaType=json"
  end
end
