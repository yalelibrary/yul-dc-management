# frozen_string_literal: true

namespace :yale do
  desc "Refresh fixture data from metadata cloud"
  task refresh_fixture_data: :environment do
    metadata_source = ENV["METADATA_SOURCE"]
    oid_path = Rails.root.join("spec", "fixtures", "fixture_ids.csv")
    MetadataCloudService.refresh_fixture_data(oid_path, metadata_source)
    puts "Data refreshed from metadata cloud"
  end
end
