# frozen_string_literal: true

namespace :yale do
  desc "Index fixture data"
  task index_fixture_data: :environment do
    FixtureIndexingService.index_fixture_data
    puts "Sample metadata indexed"
  end

  desc "Delete all solr documents"
  task clean_solr: :environment do
    solr_core = ENV["SOLR_CORE"]
    solr_url = ENV["SOLR_URL"] ||= "http://localhost:8983/solr"
    solr = RSolr.connect url: "#{solr_url}/#{solr_core}"
    solr.delete_by_query '*:*'
    solr.commit
    puts "All documents deleted from solr"
  end
end
