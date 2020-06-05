# frozen_string_literal: true
require "rails_helper"

RSpec.describe FixtureIndexingService, clean: true do
  let(:ladybird_metadata_path) { File.join(fixture_path, 'ladybird') }
  let(:oid) { "2034600" }

  it "can index the contents of a directory to Solr" do
    FixtureIndexingService.index_fixture_data
    solr = SolrService.connection
    response = solr.get 'select', params: { q: '*:*' }
    expect(response["response"]["numFound"]).to be > 45
    expect(response["response"]["numFound"]).to be < 101
  end

  it "knows where to find the ladybird metadata" do
    expect(FixtureIndexingService.ladybird_metadata_path).to eq ladybird_metadata_path
  end

  it "can index a single file to Solr" do
    FixtureIndexingService.index_to_solr(oid)
    solr = SolrService.connection
    response = solr.get 'select', params: { q: '*:*' }
    expect(response["response"]["numFound"]).to eq 1
  end

  context "Private objects" do
    let(:priv_oid) { "16189097-priv" }

    it "indexes Private as one of the visibility values" do
      FixtureIndexingService.index_to_solr(priv_oid)
      solr = SolrService.connection
      response = solr.get 'select', params: { q: '*:*' }
      expect(response["response"]["docs"].first["visibility_ssi"]).to eq("Private")
      expect(response["response"]["docs"].first.dig("title_tsim").join).to eq("[Map of China]. [private copy]")
    end

    it "can find objects according to visibility" do
      FixtureIndexingService.index_fixture_data
      solr = SolrService.connection
      response = solr.get 'select', params: { q: 'visibility_ssi:"Private"' }
      expect(response["response"]["numFound"]).to eq 2
    end
  end

  context "Yale Community Only objects" do
    let(:yale_oid) { "2107188-yale" }

    it "indexes Yale Community Only as one of the visibility values" do
      FixtureIndexingService.index_to_solr(yale_oid)
      solr = SolrService.connection
      response = solr.get 'select', params: { q: '*:*' }
      expect(response["response"]["docs"].first["visibility_ssi"]).to eq("Yale Community Only")
      expect(response["response"]["docs"].first.dig("title_tsim").join).to eq("Fair Lucretia’s garland [yale-only copy]")
    end

    it "can find objects according to visibility" do
      FixtureIndexingService.index_fixture_data
      solr = SolrService.connection
      response = solr.get 'select', params: { q: 'visibility_ssi:"Yale Community Only"' }
      expect(response["response"]["numFound"]).to eq 2
    end
  end
end
