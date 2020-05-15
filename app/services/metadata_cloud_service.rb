# frozen_string_literal: true

class MetadataCloudService
  def mc_get
    metadata_cloud_username = ENV["MC_USER"]
    metadata_cloud_password = ENV["MC_PW"]
    HTTP.basic_auth(user: metadata_cloud_username, pass: metadata_cloud_password).get("https://metadata-api-test.library.yale.edu/metadatacloud/api/ladybird/oid/16371272?mediaType=json")
  end
end
