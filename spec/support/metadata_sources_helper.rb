# frozen_string_literal: true

module MetdataSourcesHelper
  # Setup rspec
  RSpec.configure do |config|
    config.before(prep_metadata_sources: true) do
      FactoryBot.create(:metadata_source) if MetadataSource.count < 1
      FactoryBot.create(:metadata_source_voyager) if MetadataSource.count < 2
      FactoryBot.create(:metadata_source_aspace) if MetadataSource.count < 3
      FactoryBot.create(:metadata_source_sierra) if MetadataSource.count < 4
      FactoryBot.create(:metadata_source_alma) if MetadataSource.count < 5
    end
  end
end
