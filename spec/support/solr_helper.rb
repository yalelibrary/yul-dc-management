# frozen_string_literal: true

module SolrHelper
  # Setup rspec
  RSpec.configure do |config|
    def solr
      @solr || SolrService.connection
    end

    config.around(solr: true) do |e|
      SolrService.delete_all
      e.run
      SolrService.delete_all
    end
  end
end
