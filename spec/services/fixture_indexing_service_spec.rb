# frozen_string_literal: true
require "rails_helper"

RSpec.describe FixtureIndexingService, clean: true, prep_metadata_sources: true do
  context "indexing to Solr from the database with Ladybird ParentObjects" do
    let(:parent_object_1) { FactoryBot.create(:parent_object, oid: "2034600") }
    let(:parent_object_2) { FactoryBot.create(:parent_object, oid: "2046567") }
    let(:parent_object_3) { FactoryBot.create(:parent_object, oid: "16414889") }
    let(:parent_object_4) { FactoryBot.create(:parent_object, oid: "14716192") }
    let(:parent_object_5) { FactoryBot.create(:parent_object, oid: "16854285") }

    let(:metadata_cloud_response_body_1) { File.open(File.join(fixture_path, "ladybird", "2034600.json")).read }
    let(:metadata_cloud_response_body_2) { File.open(File.join(fixture_path, "ladybird", "2046567.json")).read }
    let(:metadata_cloud_response_body_3) { File.open(File.join(fixture_path, "ladybird", "16414889.json")).read }
    let(:metadata_cloud_response_body_4) { File.open(File.join(fixture_path, "ladybird", "14716192.json")).read }
    let(:metadata_cloud_response_body_5) { File.open(File.join(fixture_path, "ladybird", "16854285.json")).read }
    before do
      stub_request(:get, "https://yul-development-samples.s3.amazonaws.com/ladybird/2034600.json")
        .to_return(status: 200, body: metadata_cloud_response_body_1)
      stub_request(:get, "https://yul-development-samples.s3.amazonaws.com/ladybird/2046567.json")
        .to_return(status: 200, body: metadata_cloud_response_body_2)
      stub_request(:get, "https://yul-development-samples.s3.amazonaws.com/ladybird/16414889.json")
        .to_return(status: 200, body: metadata_cloud_response_body_3)
      stub_request(:get, "https://yul-development-samples.s3.amazonaws.com/ladybird/14716192.json")
        .to_return(status: 200, body: metadata_cloud_response_body_4)
      stub_request(:get, "https://yul-development-samples.s3.amazonaws.com/ladybird/16854285.json")
        .to_return(status: 200, body: metadata_cloud_response_body_5)
      parent_object_1
      parent_object_2
      parent_object_3
      parent_object_4
      parent_object_5
    end
    it "can index the 5 parent objects in the database to Solr" do
      expect(ParentObject.count).to eq 5
      solr = SolrService.connection
      response = solr.get 'select', params: { q: '*:*' }
      expect(response["response"]["numFound"]).to eq 0
      described_class.index_from_database_to_solr
      response = solr.get 'select', params: { q: '*:*' }
      expect(response["response"]["numFound"]).to eq 5
    end
  end
  context "with ArchiveSpace fixture data" do
    let(:metadata_fixture_path) { File.join(fixture_path, metadata_source) }
    let(:oid) { "16854285" }
    let(:metadata_source) { "aspace" }
    let(:non_aspace_oid) { "14716192" }

    it "knows where to find the ArchiveSpace metadata" do
      expect(described_class.metadata_path(metadata_source)).to eq metadata_fixture_path
    end

    it "can index a single file to Solr" do
      described_class.index_from_fixture_to_solr(oid, metadata_source)
      solr = SolrService.connection
      response = solr.get 'select', params: { q: '*:*' }
      expect(response["response"]["numFound"]).to eq 1
    end

    it "does not try to index a non-existent file to Solr" do
      described_class.index_from_fixture_to_solr(non_aspace_oid, metadata_source)
      solr = SolrService.connection
      response = solr.get 'select', params: { q: '*:*' }
      expect(response["response"]["numFound"]).to eq 0
    end

    it "can index the contents of a CSV file to Solr" do
      described_class.index_fixture_data(metadata_source)
      solr = SolrService.connection
      response = solr.get 'select', params: { q: '*:*' }
      expect(response["response"]["numFound"]).to be > 4
      expect(response["response"]["numFound"]).to be < 20
    end
  end

  context "with Voyager fixture data" do
    let(:metadata_fixture_path) { File.join(fixture_path, metadata_source) }
    let(:oid) { "2012036" }
    let(:metadata_source) { "ils" }
    let(:id_prefix) { "V-" }

    it "knows where to find the Voyager metadata" do
      expect(described_class.metadata_path(metadata_source)).to eq metadata_fixture_path
    end

    it "can index a single file to Solr" do
      described_class.index_from_fixture_to_solr(oid, metadata_source)
      solr = SolrService.connection
      response = solr.get 'select', params: { q: '*:*' }
      expect(response["response"]["numFound"]).to eq 1
    end

    it "can index the contents of a CSV file to Solr" do
      described_class.index_fixture_data(metadata_source)
      solr = SolrService.connection
      response = solr.get 'select', params: { q: '*:*' }
      expect(response["response"]["numFound"]).to be > 45
      expect(response["response"]["numFound"]).to be < 101
    end

    context "with a public item" do
      let(:parent_object_with_public_visibility) { FactoryBot.create(:parent_object, oid: oid, visibility: "Public") }

      before do
        stub_request(:get, "https://yul-development-samples.s3.amazonaws.com/ladybird/2012036.json")
          .to_return(status: 200, body: File.open(File.join(fixture_path, "ladybird", "2012036.json")).read)
        stub_request(:get, "https://yul-development-samples.s3.amazonaws.com/ils/V-2012036.json")
          .to_return(status: 200, body: File.open(File.join(fixture_path, "ils", "V-2012036.json")).read)
        stub_request(:get, "https://yul-development-samples.s3.amazonaws.com/aspace/AS-2012036.json")
          .to_return(status: 200, body: File.open(File.join(fixture_path, "aspace", "AS-2012036.json")).read)
      end

      it "can create a Solr document for a record, including visibility from Ladybird" do
        parent_object_with_public_visibility
        data_hash = FixtureParsingService.fixture_file_to_hash(oid, metadata_source)
        solr_document = described_class.build_solr_document(id_prefix, oid, data_hash)
        expect(solr_document[:title_tsim]).to eq ["Walt Whitman collection, 1842-1949"]
        expect(solr_document[:visibility_ssi]).to include "Public"
      end

      it "can index an item's image count to Solr" do
        parent_object_with_public_visibility
        data_hash = FixtureParsingService.fixture_file_to_hash(oid, metadata_source)
        solr_document = described_class.build_solr_document(id_prefix, oid, data_hash)
        expect(solr_document[:imageCount_isi]).to eq 5
      end
    end
    context "with an item without visibility" do
      let(:no_vis_oid) { "16189097-no_vis" }
      let(:parent_object_without_visibility) { FactoryBot.create(:parent_object, oid: no_vis_oid) }

      before do
        stub_request(:get, "https://yul-development-samples.s3.amazonaws.com/ladybird/16189097-no_vis.json")
          .to_return(status: 200, body: File.open(File.join(fixture_path, "ladybird", "16189097-no_vis.json")).read)
        stub_request(:get, "https://yul-development-samples.s3.amazonaws.com/V-16189097-no_vis.json")
          .to_return(status: 200, body: File.open(File.join(fixture_path, "ils", "V-16189097-no_vis.json")).read)
      end

      it "does not assign a visibility if one does not exist" do
        parent_object_without_visibility
        data_hash = FixtureParsingService.fixture_file_to_hash(no_vis_oid, metadata_source)
        solr_document = described_class.build_solr_document(id_prefix, no_vis_oid, data_hash)
        expect(solr_document[:title_tsim].first).to include "Dai Min kyūhen bankoku jinseki rotei zenzu"
        expect(solr_document[:visibility_ssi]).to be nil
      end
    end

    context "with a private item" do
      let(:priv_oid) { "16189097-priv" }
      let(:parent_object_with_private_visibility) { FactoryBot.create(:parent_object, oid: priv_oid, visibility: "Private") }
      before do
        stub_request(:get, "https://yul-development-samples.s3.amazonaws.com/ladybird/16189097-priv.json")
          .to_return(status: 200, body: File.open(File.join(fixture_path, "ladybird", "16189097-priv.json")).read)
        stub_request(:get, "https://yul-development-samples.s3.amazonaws.com/ils/V-16189097-priv.json")
          .to_return(status: 200, body: File.open(File.join(fixture_path, "ils", "V-16189097-priv.json")).read)
      end

      it "assigns private visibility from Ladybird data" do
        parent_object_with_private_visibility
        data_hash = FixtureParsingService.fixture_file_to_hash(priv_oid, metadata_source)
        solr_document = described_class.build_solr_document(id_prefix, priv_oid, data_hash)
        expect(solr_document[:title_tsim].first).to include "Dai Min kyūhen bankoku jinseki rotei zenzu"
        expect(solr_document[:visibility_ssi]).to include "Private"
      end
    end
  end

  context "with combined fixture data" do
    let(:oid) { "2034600" }

    it "can index the same digital object's data from two different metadata sources to Solr" do
      described_class.index_from_fixture_to_solr(oid, "ladybird")
      described_class.index_from_fixture_to_solr(oid, "ils")
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
      described_class.index_fixture_data(metadata_source)
      solr = SolrService.connection
      response = solr.get 'select', params: { q: '*:*' }
      expect(response["response"]["numFound"]).to be > 45
      expect(response["response"]["numFound"]).to be < 101
    end

    it "knows where to find the ladybird metadata" do
      expect(described_class.metadata_path(metadata_source)).to eq metadata_fixture_path
    end

    it "can index a single file to Solr" do
      described_class.index_from_fixture_to_solr(oid, metadata_source)
      solr = SolrService.connection
      response = solr.get 'select', params: { q: '*:*' }
      expect(response["response"]["numFound"]).to eq 1
    end

    it "can create a Solr document for a record" do
      data_hash = FixtureParsingService.fixture_file_to_hash(oid, metadata_source)
      solr_document = described_class.build_solr_document(id_prefix, oid, data_hash)
      expect(solr_document[:title_tsim]).to include "[Magazine page with various photographs of Leontyne Price]"
      expect(solr_document[:visibility_ssi]).to include "Public"
    end

    context "Private objects" do
      let(:priv_oid) { "16189097-priv" }

      it "indexes Private as one of the visibility values" do
        described_class.index_from_fixture_to_solr(priv_oid, metadata_source)
        solr = SolrService.connection
        response = solr.get 'select', params: { q: '*:*' }
        expect(response["response"]["docs"].first["visibility_ssi"]).to eq("Private")
        expect(response["response"]["docs"].first.dig("title_tsim").join).to eq("[Map of China]. [private copy]")
      end

      it "can find objects according to visibility" do
        described_class.index_fixture_data(metadata_source)
        solr = SolrService.connection
        response = solr.get 'select', params: { q: 'visibility_ssi:"Private"' }
        expect(response["response"]["numFound"]).to eq 2
      end
    end

    context "Yale Community Only objects" do
      let(:yale_oid) { "2107188-yale" }

      it "indexes Yale Community Only as one of the visibility values" do
        described_class.index_from_fixture_to_solr(yale_oid, metadata_source)
        solr = SolrService.connection
        response = solr.get 'select', params: { q: '*:*' }
        expect(response["response"]["docs"].first["visibility_ssi"]).to eq("Yale Community Only")
        expect(response["response"]["docs"].first.dig("title_tsim").join).to eq("Fair Lucretia’s garland [yale-only copy]")
      end

      it "can find objects according to visibility" do
        described_class.index_fixture_data(metadata_source)
        solr = SolrService.connection
        response = solr.get 'select', params: { q: 'visibility_ssi:"Yale Community Only"' }
        expect(response["response"]["numFound"]).to eq 2
      end
    end
  end
end
