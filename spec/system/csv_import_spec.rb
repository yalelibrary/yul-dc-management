# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "Oid CSV Import", type: :system do
  before do
    visit management_index_path
  end

  context "with existing oids" do
    before do
      find_by_id("file").click
      attach_file("Upload Your File", Rails.root + "spec/fixtures/short_fixture_ids.csv")
    end
    it "Does not error" do
      expect(response).to have_http_status(:success)
    end
  end
end
