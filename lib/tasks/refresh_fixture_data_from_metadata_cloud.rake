# frozen_string_literal: true

namespace :yale do
  desc "Refresh fixture data from metadata cloud"
  task refresh_fixture_data: :environment do
    oid_path = Rails.root.join("spec", "fixtures", "fixture_ids.csv")
    MetadataCloudService.refresh_fixture_data(oid_path)
  end
end
