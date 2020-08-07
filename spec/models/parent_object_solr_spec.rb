# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ParentObject, type: :model, prep_metadata_sources: true, solr: true do
  context "indexing to Solr from the database with Ladybird ParentObjects" do
    it "can index the 5 parent objects in the database to Solr" do
      response = solr.get 'select', params: { q: '*:*' }
      expect(response["response"]["numFound"]).to eq 0

      expect do
        @parent_objects = []
        [
          '2034600',
          '2046567',
          '16414889',
          '14716192',
          '16854285'
        ].each do |oid|
          stub_metadata_cloud(oid)
          @parent_objects << FactoryBot.create(:parent_object, oid: oid)
        end
      end.to change{ ParentObject.count }.by(5)

      response = solr.get 'select', params: { q: '*:*' }
      expect(response["response"]["numFound"]).to eq 5
    end
  end
end
