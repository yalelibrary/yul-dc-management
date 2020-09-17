# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ParentObject, type: :model, prep_metadata_sources: true do
  # this doesn't seem to run from a helper, not clear why
  around do |example|
    perform_enqueued_jobs do
      example.run
    end
  end

  before do
    stub_ptiffs_and_manifests
    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(ParentObject).to receive(:manifest_completed?).and_return(true)
    # rubocop:enable RSpec/AnyInstance
  end

  describe "changing the authoritative metadata source", solr: true do
    let(:oid) { "2034600" }
    let(:parent_object) { FactoryBot.create(:parent_object, oid: oid, source_name: 'ladybird', visibility: "Public") }
    before do
      stub_metadata_cloud(oid)
      parent_object
    end
    it "indexes the ladybird_json then overwrites with the Voyager json" do
      solr_document = parent_object.reload.to_solr
      expect(solr_document[:title_tesim]).to eq ["[Magazine page with various photographs of Leontyne Price]"]
      parent_object.source_name = "ils"
      parent_object.save!
      solr_document = parent_object.reload.to_solr
      expect(solr_document[:title_tesim]).to eq ["Ebony"]
      response = solr.get 'select', params: { q: '*:*' }
      expect(response["response"]["numFound"]).to eq 1
    end
  end

  context "indexing to Solr from the database with Ladybird ParentObjects", solr: true do
    it "can index the 5 parent objects in the database to Solr" do
      response = solr.get 'select', params: { q: '*:*' }
      expect(response["response"]["numFound"]).to eq 0

      expect do
        [
          '2034600',
          '2005512',
          '16414889',
          '14716192',
          '16854285'
        ].each do |oid|
          stub_metadata_cloud(oid)
          FactoryBot.create(:parent_object, oid: oid)
        end
      end.to change { ParentObject.count }.by(5)

      response = solr.get 'select', params: { q: '*:*' }
      expect(response["response"]["numFound"]).to eq 5
    end
  end

  context "with Voyager fixture data" do
    let(:oid) { "2012036" }
    let(:metadata_source) { "ils" }
    let(:id_prefix) { "V-" }

    context "with a public item" do
      let(:parent_object_with_public_visibility) { FactoryBot.create(:parent_object, oid: oid, source_name: 'ils', visibility: "Public") }
      around do |example|
        original_image_url = ENV['IIIF_IMAGE_BASE_URL']
        ENV['IIIF_IMAGE_BASE_URL'] = "http://localhost:8182/iiif"
        example.run
        ENV['IIIF_IMAGE_BASE_URL'] = original_image_url
      end
      before do
        stub_metadata_cloud(oid.to_s)
        stub_metadata_cloud("V-#{oid}", "ils")
        stub_metadata_cloud("AS-#{oid}", "aspace")
      end

      it "can create a Solr document for a record, including visibility from Ladybird" do
        solr_document = parent_object_with_public_visibility.reload.to_solr
        expect(solr_document[:title_tsim]).to eq ["Walt Whitman collection, 1842-1949"]
        expect(solr_document[:visibility_ssi]).to include "Public"
      end

      it "can index an item's image count to Solr" do
        solr_document = parent_object_with_public_visibility.reload.to_solr
        expect(solr_document[:imageCount_isi]).to eq 5
      end

      it "can index a thumbnail path to Solr" do
        solr_document = parent_object_with_public_visibility.reload.to_solr
        expect(solr_document[:thumbnail_path_ss]).to eq "http://localhost:8182/iiif/2/1052760/full/!200,200/0/default.jpg"
      end
    end

    context "with mocked items without a metadatacloud equivalent" do
      around do |example|
        original_vpn = ENV['VPN']
        ENV['VPN'] = 'false'
        example.run
        ENV['VPN'] = original_vpn
      end

      context "with an item without visibility" do
        let(:no_vis_oid) { "30000016189097" }
        let(:parent_object_without_visibility) { FactoryBot.create(:parent_object, oid: no_vis_oid, source_name: 'ils') }

        before do
          stub_metadata_cloud(no_vis_oid.to_s)
          stub_metadata_cloud("V-#{no_vis_oid}", 'ils')
        end

        it "does not assign a visibility if one does not exist" do
          solr_document = parent_object_without_visibility.reload.to_solr
          expect(solr_document[:title_tsim].first).to include "Dai Min kyūhen bankoku jinseki rotei zenzu"
          expect(solr_document[:visibility_ssi]).to be nil
        end
      end

      context "with a private item" do
        let(:priv_oid) { "10000016189097" }
        let(:parent_object_with_private_visibility) { FactoryBot.create(:parent_object, oid: priv_oid, visibility: "Private", source_name: 'ils') }

        before do
          stub_metadata_cloud(priv_oid)
          stub_metadata_cloud("V-#{priv_oid}", 'ils')
        end

        it "assigns private visibility from Ladybird data" do
          solr_document = parent_object_with_private_visibility.reload.to_solr
          expect(solr_document[:title_tsim].first).to include "Dai Min kyūhen bankoku jinseki rotei zenzu"
          expect(solr_document[:visibility_ssi]).to include "Private"
        end
      end
    end
  end
end
