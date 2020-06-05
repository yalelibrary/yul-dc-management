# frozen_string_literal: true

namespace :yale do
  desc "Index fixture data"
  task index_fixture_data: :environment do
    FixtureIndexingService.index_fixture_data
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
