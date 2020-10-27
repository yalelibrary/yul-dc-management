# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "Batch Process Parent detail page", type: :system, prep_metadata_sources: true do
  let(:user) { FactoryBot.create(:user, uid: "johnsmith2530") }
  before do
    stub_metadata_cloud("2004628")
    stub_metadata_cloud("2030006")
    stub_metadata_cloud("2034600")
    stub_metadata_cloud("16057779")
    stub_metadata_cloud("15234629")
    login_as user
    visit batch_process_path(batch_process)
  end

  describe "with a csv import" do
    let(:batch_process) do
      FactoryBot.create(
        :batch_process,
        user: user,
        csv: File.open(fixture_path + '/small_short_fixture_ids.csv').read,
        file_name: "small_short_fixture_ids.csv",
        created_at: "2020-10-08 14:17:01"
      )
    end

    it "can go to a parent batch process page" do
      visit parent_objects_batch_process_path(batch_process)
      expect(page.body).to have_link('16057779', href: "/batch_process/#{batch_process.id}/parent_objects/16057779")
      click_on('16057779')
      expect(page.body).to include "Parent Job Detail Page"
    end

    it "can go to a parent batch process detail page" do
      expect(page.body).to have_link('16057779', href: "/batch_process/#{batch_process.id}/parent_objects/16057779")
      click_on('16057779')
      expect(page.body).to include "Parent Job Detail Page"
    end
  end
end
