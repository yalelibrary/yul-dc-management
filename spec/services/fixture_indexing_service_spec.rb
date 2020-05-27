# frozen_string_literal: true
require "rails_helper"

RSpec.describe FixtureIndexingService, clean: true do
  let(:ladybird_metadata_path) { File.join(fixture_path, 'ladybird') }
  let(:solr_core) { ENV["SOLR_TEST_CORE"] ||= "blacklight-test" }
  let(:solr_url) { ENV["SOLR_URL"] ||= "http://localhost:8983/solr" }
  let(:oid) { "2034600" }

  it "can index the contents of a directory to Solr" do
    FixtureIndexingService.index_fixture_data
    solr = RSolr.connect url: "#{solr_url}/#{solr_core}"
    response = solr.get 'select', params: { q: '*:*' }
    expect(response["response"]["numFound"]).to be > 45
    expect(response["response"]["numFound"]).to be < 101
  end

  it "knows where to find the ladybird metadata" do
    expect(FixtureIndexingService.ladybird_metadata_path).to eq ladybird_metadata_path
  end

  it "can index a single file to Solr" do
    FixtureIndexingService.index_to_solr(oid)
    solr = RSolr.connect url: "#{solr_url}/#{solr_core}"
    response = solr.get 'select', params: { q: '*:*' }
    expect(response["response"]["numFound"]).to eq 1
  end

  context "it can index private files" do
    let(:priv_oid) { "16189097-priv" }

    it "can determine if a file is private" do
      FixtureIndexingService.index_to_solr(priv_oid)
      solr = RSolr.connect url: "#{solr_url}/#{solr_core}"
      response = solr.get 'select', params: { q: '*:*' }
      expect(response["response"]["docs"].first["id"]).to eq("16189097-priv")
      expect(response["response"]["docs"].first.dig("title_tsim").join).to eq("[Map of China]. [private copy]")
    end

    it "can index the private contents of a directory to Solr" do
      FixtureIndexingService.index_fixture_data
      solr = RSolr.connect url: "#{solr_url}/#{solr_core}"
      response = solr.get 'select', params: { q: '[private copy]' }
      expect(response["response"]["numFound"]).to eq 2
    end
  end

  context "it can index yale-only files" do
    let(:rest_oid) { "2107188-yale" }

    it "can determine if a file is restricted to Yale only" do
      FixtureIndexingService.index_to_solr(rest_oid)
      solr = RSolr.connect url: "#{solr_url}/#{solr_core}"
      response = solr.get 'select', params: { q: '*:*' }
      expect(response["response"]["docs"].first["id"]).to eq("2107188-yale")
      expect(response["response"]["docs"].first.dig("title_tsim").join).to eq("Fair Lucretia’s garland [yale-only copy]")
    end

    it "can index the yale-only contents of a directory to Solr" do
      FixtureIndexingService.index_fixture_data
      solr = RSolr.connect url: "#{solr_url}/#{solr_core}"
      response = solr.get 'select', params: { q: '[yale-only copy]' }
      expect(response["response"]["numFound"]).to eq 2
    end
  end
end
