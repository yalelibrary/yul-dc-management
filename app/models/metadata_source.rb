# frozen_string_literal: true

class MetadataSource < ApplicationRecord
  has_many :parent_objects, foreign_key: "authoritative_metadata_source_id"
  class MetadataCloudServerError < StandardError
    def message
      "MetadataCloud is responding with 5XX error"
    end
  end

  def fetch_record(parent_object)
    # The environment value has to be set as a string, real booleans do not work
    raw_metadata = if ENV["VPN"] == "true"
                     fetch_record_on_vpn(parent_object)
                   else
                     s3_path = "#{metadata_cloud_name}/#{file_name(parent_object)}"
                     r = S3Service.download(s3_path)
                     parent_object.processing_event("S3 did not return json for #{s3_path}", "failed") unless r.present?
                     r
                   end
    return unless raw_metadata
    JSON.parse(raw_metadata)
  end

  def fetch_record_on_vpn(parent_object)
    mc_url = parent_object.send(url_type)
    full_response = mc_get(mc_url)
    case full_response.status
    when 200
      response_text = full_response.body.to_str
      S3Service.upload("#{metadata_cloud_name}/#{file_name(parent_object)}", response_text)
      response_text
    when 400...500
      parent_object.processing_event("Metadata Cloud did not return json. Response was #{full_response.status.code} - #{full_response.status.reason}", "failed")
      false
    when 500...600
      parent_object.processing_event("Metadata Cloud did not return json. Response was #{full_response.status.code} - #{full_response.status.reason}", "failed")
      raise MetadataSource::MetadataCloudServerError
    else
      parent_object.processing_event("Metadata Cloud did not return json. Response was #{full_response.status.code} - #{full_response.status.reason}", "failure")
      false
    end
  end

  def file_name(parent_object)
    "#{file_prefix}#{parent_object.oid}.json"
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
    # TODO: Do we still need the Honeybadger context part of this?
    Honeybadger.context(
      metadata_cloud_username: ENV["MC_USER"],
      metadata_cloud_password: ENV["MC_PW"],
      mc_host: MetadataSource.metadata_cloud_host,
      mc_host_env: ENV['METADATA_CLOUD_HOST'],
      mc_url: mc_url
    )
    metadata_cloud_username = ENV["MC_USER"]
    metadata_cloud_password = ENV["MC_PW"]
    HTTP.basic_auth(user: metadata_cloud_username, pass: metadata_cloud_password).get(mc_url)
  end

  # Hard coding the metadata cloud version because it is directly correlated with the solr indexing code
  def self.metadata_cloud_version
    "1.0.1"
  end

  def self.metadata_cloud_host
    ENV['METADATA_CLOUD_HOST'].present? ? ENV['METADATA_CLOUD_HOST'] : 'metadata-api-uat.library.yale.edu'
  end
end
