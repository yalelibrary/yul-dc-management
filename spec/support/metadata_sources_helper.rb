# frozen_string_literal: true

module MetdataSourcesHelper
  # Setup rspec
  RSpec.configure do |config|
    config.before(prep_metadata_sources: true) do
      FactoryBot.create(:metadata_source) if MetadataSource.all.count == 0
      FactoryBot.create(:metadata_source_voyager) if MetadataSource.all.count == 1
      FactoryBot.create(:metadata_source_aspace) if MetadataSource.all.count == 2
    end
  end
end
