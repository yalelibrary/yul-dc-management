# frozen_string_literal: true
require "rails_helper"

RSpec.describe FixtureIndexingService, clean: true do
  context "with ArchiveSpace fixture data" do
    let(:metadata_fixture_path) { File.join(fixture_path, metadata_source) }
    let(:oid) { "16854285" }
    let(:metadata_source) { "aspace" }
    let(:non_aspace_oid) { "14716192" }
    let(:parent_object_with_public_visibility) { FactoryBot.create(:parent_object, oid: oid, visibility: "Public") }

    it "knows where to find the ArchiveSpace metadata" do
      expect(FixtureIndexingService.metadata_path(metadata_source)).to eq metadata_fixture_path
    end

    it "can index a single file to Solr" do
      FixtureIndexingService.index_to_solr(oid, metadata_source)
      solr = SolrService.connection
      response = solr.get 'select', params: { q: '*:*' }
      expect(response["response"]["numFound"]).to eq 1
    end

    it "does not try to index a non-existent file to Solr" do
      FixtureIndexingService.index_to_solr(non_aspace_oid, metadata_source)
      solr = SolrService.connection
      response = solr.get 'select', params: { q: '*:*' }
      expect(response["response"]["numFound"]).to eq 0
    end

    it "can index the contents of a CSV file to Solr" do
      FixtureIndexingService.index_fixture_data(metadata_source)
      solr = SolrService.connection
      response = solr.get 'select', params: { q: '*:*' }
      expect(response["response"]["numFound"]).to be > 4
      expect(response["response"]["numFound"]).to be < 20
    end
  end

  context "with Voyager fixture data" do
    let(:metadata_fixture_path) { File.join(fixture_path, metadata_source) }
    let(:oid) { "2034600" }
    let(:priv_oid) { "16189097-priv" }
    let(:metadata_source) { "ils" }
    let(:id_prefix) { "V-" }
    let(:parent_object_with_public_visibility) { FactoryBot.create(:parent_object, oid: oid, visibility: "Public") }
    let(:parent_object_without_visibility) { FactoryBot.create(:parent_object, oid: oid) }
    let(:parent_object_with_private_visibility) { FactoryBot.create(:parent_object, oid: priv_oid, visibility: "Private") }

    it "knows where to find the Voyager metadata" do
      expect(FixtureIndexingService.metadata_path(metadata_source)).to eq metadata_fixture_path
    end

    it "can index a single file to Solr" do
      FixtureIndexingService.index_to_solr(oid, metadata_source)
      solr = SolrService.connection
      response = solr.get 'select', params: { q: '*:*' }
      expect(response["response"]["numFound"]).to eq 1
    end

    it "can index the contents of a CSV file to Solr" do
      FixtureIndexingService.index_fixture_data(metadata_source)
      solr = SolrService.connection
      response = solr.get 'select', params: { q: '*:*' }
      expect(response["response"]["numFound"]).to be > 45
      expect(response["response"]["numFound"]).to be < 101
    end

    it "can create a Solr document for a record, including visibility from Ladybird" do
      parent_object_with_public_visibility
      mcs = MetadataCloudService.new
      data_hash = mcs.fixture_file_to_hash(oid, metadata_source)
      fis = FixtureIndexingService.new
      solr_document = fis.build_solr_document(id_prefix, oid, data_hash)
      expect(solr_document[:title_tsim]).to include "Ebony"
      expect(solr_document[:visibility_ssi]).to include "Public"
    end

    it "does not assign a visibility if one does not exist" do
      parent_object_without_visibility
      mcs = MetadataCloudService.new
      data_hash = mcs.fixture_file_to_hash(oid, metadata_source)
      fis = FixtureIndexingService.new
      solr_document = fis.build_solr_document(id_prefix, oid, data_hash)
      expect(solr_document[:title_tsim]).to include "Ebony"
      expect(solr_document[:visibility_ssi]).to be nil
    end

    it "assigns private visibility from Ladybird data" do
      parent_object_with_private_visibility
      mcs = MetadataCloudService.new
      data_hash = mcs.fixture_file_to_hash(priv_oid, metadata_source)
      fis = FixtureIndexingService.new
      solr_document = fis.build_solr_document(id_prefix, priv_oid, data_hash)
      expect(solr_document[:title_tsim].first).to include "Dai Min kyūhen bankoku jinseki rotei zenzu"
      expect(solr_document[:visibility_ssi]).to include "Private"
    end
  end

  context "with combined fixture data" do
    let(:oid) { "2034600" }

    it "can index the same digital object's data from two different metadata sources to Solr" do
      FixtureIndexingService.index_to_solr(oid, "ladybird")
      FixtureIndexingService.index_to_solr(oid, "ils")
      solr = SolrService.connection
      response = solr.get 'select', params: { q: '*:*' }
      expect(response["response"]["numFound"]).to eq 2
    end
  end

  context "with ladybird fixture data" do
    let(:metadata_fixture_path) { File.join(fixture_path, metadata_source) }
    let(:oid) { "2034600" }
    let(:metadata_source) { "ladybird" }
    let(:id_prefix) { "" }

    it "can index the contents of a directory to Solr" do
      FixtureIndexingService.index_fixture_data(metadata_source)
      solr = SolrService.connection
      response = solr.get 'select', params: { q: '*:*' }
      expect(response["response"]["numFound"]).to be > 45
      expect(response["response"]["numFound"]).to be < 101
    end

    it "knows where to find the ladybird metadata" do
      expect(FixtureIndexingService.metadata_path(metadata_source)).to eq metadata_fixture_path
    end

    it "can index a single file to Solr" do
      FixtureIndexingService.index_to_solr(oid, metadata_source)
      solr = SolrService.connection
      response = solr.get 'select', params: { q: '*:*' }
      expect(response["response"]["numFound"]).to eq 1
    end

    it "can create a Solr document for a record" do
      mcs = MetadataCloudService.new
      data_hash = mcs.fixture_file_to_hash(oid, metadata_source)
      fis = FixtureIndexingService.new
      solr_document = fis.build_solr_document(id_prefix, oid, data_hash)
      expect(solr_document[:title_tsim]).to include "[Magazine page with various photographs of Leontyne Price]"
      expect(solr_document[:visibility_ssi]).to include "Public"
    end

    context "Private objects" do
      let(:priv_oid) { "16189097-priv" }

      it "indexes Private as one of the visibility values" do
        FixtureIndexingService.index_to_solr(priv_oid, metadata_source)
        solr = SolrService.connection
        response = solr.get 'select', params: { q: '*:*' }
        expect(response["response"]["docs"].first["visibility_ssi"]).to eq("Private")
        expect(response["response"]["docs"].first.dig("title_tsim").join).to eq("[Map of China]. [private copy]")
      end

      it "can find objects according to visibility" do
        FixtureIndexingService.index_fixture_data(metadata_source)
        solr = SolrService.connection
        response = solr.get 'select', params: { q: 'visibility_ssi:"Private"' }
        expect(response["response"]["numFound"]).to eq 2
      end
    end

    context "Yale Community Only objects" do
      let(:yale_oid) { "2107188-yale" }

      it "indexes Yale Community Only as one of the visibility values" do
        FixtureIndexingService.index_to_solr(yale_oid, metadata_source)
        solr = SolrService.connection
        response = solr.get 'select', params: { q: '*:*' }
        expect(response["response"]["docs"].first["visibility_ssi"]).to eq("Yale Community Only")
        expect(response["response"]["docs"].first.dig("title_tsim").join).to eq("Fair Lucretia’s garland [yale-only copy]")
      end

      it "can find objects according to visibility" do
        FixtureIndexingService.index_fixture_data(metadata_source)
        solr = SolrService.connection
        response = solr.get 'select', params: { q: 'visibility_ssi:"Yale Community Only"' }
        expect(response["response"]["numFound"]).to eq 2
      end
    end
  end
end
