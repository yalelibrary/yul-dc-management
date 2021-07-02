# frozen_string_literal: true

namespace :fixtures do
  desc "update Archives Space fixtures"
  task update_aspace: :environment do
    fixture_updates("aspace")
  end

  desc "update ILS fixtures"
  task update_ils: :environment do
    fixture_updates("ils")
  end
end

def mc_get(mc_url)
  metadata_cloud_username = ENV["MC_USER"]
  metadata_cloud_password = ENV["MC_PW"]
  HTTP.basic_auth(user: metadata_cloud_username, pass: metadata_cloud_password).get(mc_url)
end

def fixture_updates(type)
  fixture_file_folder = Rails.root.join("spec", "fixtures", type)
  files = fixture_file_folder.glob("*.json")
  files.each do |file|
    fixture_file = File.read(file)
    metadata = JSON.parse(fixture_file)
    mc_response = mc_get("https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/#{MetadataSource.metadata_cloud_version}#{metadata['uri']}")
    next unless mc_response.status == 200
    new_metadata = mc_response.body.to_str
    metadata = JSON.parse(new_metadata)
    puts "rewriting #{file}"
    File.write(file, JSON.pretty_generate(metadata))
  end
end
