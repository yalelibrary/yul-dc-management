# frozen_string_literal: true
require 'csv'

class MetadataCloudService
  def mc_get
    metadata_cloud_username = ENV["MC_USER"]
    metadata_cloud_password = ENV["MC_PW"]
    HTTP.basic_auth(user: metadata_cloud_username, pass: metadata_cloud_password).get("https://metadata-api-test.library.yale.edu/metadatacloud/api/ladybird/oid/16371272?mediaType=json")
  end

  def oid_array
    @oid_array ||= build_oid_array
  end

  def build_oid_array
    fixture_ids_table = CSV.read(Rails.root.join("spec", "fixtures", "fixture_ids.csv"), headers: true)
    fixture_ids_table.by_col[0]
  end

  def metadata_cloud_url
    @metadata_cloud_url ||= build_metadata_cloud_url
  end

  def build_metadata_cloud_url(oid)
    "https://metadata-api-test.library.yale.edu/metadatacloud/api/ladybird/oid/#{oid}?mediaType=json"
  end
end
