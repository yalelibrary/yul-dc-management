# frozen_string_literal: true

class MetadataSource < ApplicationRecord
  has_many :parent_objects, foreign_key: "authoritative_metadata_source_id"

  def fetch_record(parent_object)
    raw_metadata = if ENV['VPN']
                     mc_url = parent_object.send(url_type)
                     full_response = mc_get(mc_url)
                     return unless full_response.status == 200
                     full_response.body.to_str
                   else
                     file = Rails.root.join('spec', 'fixtures', metadata_cloud_name, file_name(parent_object))
                     return unless File.exist?(file)
                     File.read(file)
                   end
    JSON.parse(raw_metadata)
  end

  def file_name(parent_object)
    "#{self.file_prefix}#{parent_object.oid}.json"
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
