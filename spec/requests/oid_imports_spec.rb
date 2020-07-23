# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "OID Imports", type: :request do
  let(:invalid_attributes) do
    {
      text: Rails.root + "spec/fixtures/short_fixture_ids.csv"
    }
  end

  describe "GET /new" do
    it "renders a successful response" do
      get new_oid_import_url
      expect(response).to be_successful
    end
  end

  # TODO: FIX Spec
  # describe "POST /create" do
  #   context "with an invalid csv" do
  #     before do
  #       byebug
  #       oid_import = FactoryBot.create(:oid_import)
  #       post oid_imports_url(oid_import), params: { oid_import: invalid_attributes }
  #       oid_import.stub(:save).and_return(false)
  #       byebug
  #     end

  #     it "renders a the new template" do
  #       expect(response).to render_template("new")
  #     end
  #   end
  # end
end
