# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "/versions", type: :request, prep_metadata_sources: true, prep_admin_sets: true do
  let(:user) { FactoryBot.create(:sysadmin_user) }

  before do
    stub_metadata_cloud("2004628")
    login_as user
  end

  let(:valid_attributes) do
    {
      oid: "2004628",
      authoritative_metadata_source_id: 1,
      admin_set: AdminSet.find_by_key('brbl'),
      bib: "123"
    }
  end

  describe "GET /index" do
    it "renders a successful response" do
      ParentObject.create! valid_attributes
      get parent_object_versions_path(ParentObject.first)
      expect(response).to be_successful
    end
  end
end
