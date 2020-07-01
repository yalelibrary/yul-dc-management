# frozen_string_literal: true
require 'rails_helper'

require "webmock"

WebMock.allow_net_connect!

RSpec.describe "Oid CSV Import", type: :system do
  before do
    visit management_index_path
  end

  context "with existing oids", vpn_only: true do
    before do
      # find_by_id("oid_import_file").click
      # page.attach_file("oid_import_file", Rails.root + "spec/fixtures/short_fixture_ids.csv")
    end
    it "Does not error" do
      page.attach_file("oid_import_file", Rails.root + "spec/fixtures/short_fixture_ids.csv")
      click_button("Import")
      expect(page).to have_content("Your records have been retrieved from the MetadataCloud and are ready to be indexed to Solr.")
    end
  end
end
