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
end
