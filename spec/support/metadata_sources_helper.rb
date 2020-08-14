# frozen_string_literal: true

module MetdataSourcesHelper
  # Setup rspec
  RSpec.configure do |config|
    config.before(prep_metadata_sources: true) do
      FactoryBot.create(:metadata_source)
      FactoryBot.create(:metadata_source_voyager)
      FactoryBot.create(:metadata_source_aspace)
    end
  end
end
