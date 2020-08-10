# frozen_string_literal: true

namespace :solr do
  desc "Index all database records"
  task index: :environment do
    ParentObject.solr_index
  end

  desc "Delete all solr documents"
  task delete_all: :environment do
    SolrService.delete_all
    puts "All documents deleted from solr"
  end
end
