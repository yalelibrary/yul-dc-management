# frozen_string_literal: true
require 'rails_helper'

RSpec.describe '/api/parent/oid', type: :request, prep_metadata_sources: true, prep_admin_sets: true do
  let(:valid_attributes) do
    {
      oid: "2004628",
      authoritative_metadata_source_id: 1,
      admin_set: AdminSet.find_by_key('brbl'),
      bib: "123"
    }
  end

  describe "GET with valid oid" do
    it "renders a successful response" do
      ParentObject.create! valid_attributes
      get "/api/parent/#{valid_attributes[:oid]}"
      expect(response).to be_successful
    end
  end

end