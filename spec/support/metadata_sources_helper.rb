# frozen_string_literal: true

module MetdataSourcesHelper
  # Setup rspec
  RSpec.configure do |config|
    # Each factory has a fixed id (spec/factories/metadata_sources.rb). Check by id rather than
    # counting rows, so a leftover metadata source from another spec can't stop one being created.
    config.before(prep_metadata_sources: true) do
      { metadata_source: 1, metadata_source_voyager: 2, metadata_source_aspace: 3,
        metadata_source_sierra: 4, metadata_source_alma: 5 }.each do |factory, id|
        FactoryBot.create(factory) unless MetadataSource.exists?(id: id)
      end
    end
  end
end
