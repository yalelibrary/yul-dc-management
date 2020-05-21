# frozen_string_literal: true
require "rails_helper"

RSpec.describe FixtureIndexingService, clean: true do
  let(:ladybird_metadata_path) { File.join(fixture_path, 'ladybird') }
  let(:solr_core) { ENV["SOLR_TEST_CORE"] ||= "blacklight-test" }
  let(:solr_url) { ENV["SOLR_URL"] ||= "http://localhost:8983/solr" }
  let(:oid) { "2034600" }

  xit "can index the contents of a directory to Solr" do
    FixtureIndexingService.index_fixture_data
    solr = RSolr.connect url: "#{solr_url}/#{solr_core}"
    response = solr.get 'select', params: { q: '*:*' }
    expect(response["response"]["numFound"]).to eq 45
  end

  it "knows where to find the ladybird metadata" do
    expect(FixtureIndexingService.ladybird_metadata_path).to eq ladybird_metadata_path
  end

  xit "can index a single file to Solr" do
    FixtureIndexingService.index_to_solr(oid)
    solr = RSolr.connect url: "#{solr_url}/#{solr_core}"
    response = solr.get 'select', params: { q: '*:*' }
    expect(response["response"]["numFound"]).to eq 1
  end
end