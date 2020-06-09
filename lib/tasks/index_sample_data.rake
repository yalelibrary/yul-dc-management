# frozen_string_literal: true

namespace :yale do
  desc "METADATA_SOURCE=aspace|ils|ladybird rake yale:index_fixture_data Index fixture data"
  task index_fixture_data: :environment do
    metadata_source = ENV["METADATA_SOURCE"]
    FixtureIndexingService.index_fixture_data(metadata_source)
    puts "Sample metadata indexed"
  end

  desc "Delete all solr documents"
  task clean_solr: :environment do
    solr = SolrService.connection
    solr.delete_by_query '*:*'
    solr.commit
    puts "All documents deleted from solr"
  end
end
