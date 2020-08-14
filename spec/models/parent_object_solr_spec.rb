# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ParentObject, type: :model, prep_metadata_sources: true do
  context "indexing to Solr from the database with Ladybird ParentObjects", solr: true do
    it "can index the 5 parent objects in the database to Solr" do
      response = solr.get 'select', params: { q: '*:*' }
      expect(response["response"]["numFound"]).to eq 0

      expect do
        [
          '2034600',
          '2046567',
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
    let(:metadata_fixture_path) { File.join(fixture_path, metadata_source) }
    let(:oid) { "2012036" }
    let(:metadata_source) { "ils" }
    let(:id_prefix) { "V-" }

    context "with a public item" do
      let(:parent_object_with_public_visibility) { FactoryBot.create(:parent_object, oid: oid, source_name: 'ils', visibility: "Public") }

      before do
        stub_metadata_cloud(oid.to_s)
        stub_metadata_cloud("V-#{oid}", "ils")
        stub_metadata_cloud("AS-#{oid}", "aspace")
      end

      it "can create a Solr document for a record, including visibility from Ladybird" do
        parent_object_with_public_visibility
        solr_document = parent_object_with_public_visibility.to_solr
        expect(solr_document[:title_tsim]).to eq ["Walt Whitman collection, 1842-1949"]
        expect(solr_document[:visibility_ssi]).to include "Public"
      end

      it "can index an item's image count to Solr" do
        solr_document = parent_object_with_public_visibility.to_solr
        expect(solr_document[:imageCount_isi]).to eq 5
      end
    end

    context "with an item without visibility" do
      let(:no_vis_oid) { "30000016189097" }
      let(:parent_object_without_visibility) { FactoryBot.create(:parent_object, oid: no_vis_oid, source_name: 'ils') }

      before do
        stub_metadata_cloud(no_vis_oid.to_s)
        stub_metadata_cloud("V-#{no_vis_oid}", 'ils')
      end

      it "does not assign a visibility if one does not exist" do
        solr_document = parent_object_without_visibility.to_solr
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
        solr_document = parent_object_with_private_visibility.to_solr
        expect(solr_document[:title_tsim].first).to include "Dai Min kyūhen bankoku jinseki rotei zenzu"
        expect(solr_document[:visibility_ssi]).to include "Private"
      end
    end
  end
end
