# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "Batch Process detail page", type: :system, prep_metadata_sources: true, js: true do
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

  context "when uploading a csv" do
    let(:batch_process) do
      FactoryBot.create(
        :batch_process,
        user: user,
        csv: File.open(fixture_path + '/small_short_fixture_ids.csv').read,
        file_name: "small_short_fixture_ids.csv",
        created_at: "2020-10-08 14:17:01"
      )
    end
    it "can see the details of the import" do
      expect(page).to have_content(batch_process.id.to_s)
      expect(page).to have_content("johnsmith2530")
      expect(page).to have_link("small_short_fixture_ids.csv", href: "/batch_processes/#{batch_process.id}/download")
      expect(page).to have_link('16057779', href: "/batch_processes/#{batch_process.id}/parent_objects/16057779")
      expect(page).to have_content("4")
      expect(page).to have_content("2020-10-08 14:17:01")
    end

    it "can see the status of the import" do
      expect(page).to have_content("In progress - no failures")
    end

    context "deleting a parent object" do
      before do
        batch_process
        visit batch_process_path(batch_process)
        po = ParentObject.find(16_057_779)
        po.delete
        page.refresh
      end

      it "can still see the details of the import" do
        expect(page).to have_content(batch_process.id.to_s)
        expect(page).to have_content('16057779')
        expect(page).to have_content('pending, or parent deleted')
        expect(page).to have_content('Parent object deleted')
      end
    end
  end

  context "when uploading an xml doc" do
    let(:batch_process) do
      FactoryBot.create(
        :batch_process,
        user: user,
        mets_xml: File.open(fixture_path + '/goobi/metadata/16172421/meta.xml').read,
        file_name: "meta.xml",
        created_at: "2020-10-08 16:17:01"
      )
    end
    it "can see the details of the import" do
      expect(page).to have_content(batch_process.id.to_s)
      expect(page).to have_content("johnsmith2530")
      expect(page).to have_link("meta.xml", href: "/batch_processes/#{batch_process.id}/download")
      expect(page).to have_link('16172421', href: "/batch_processes/#{batch_process.id}/parent_objects/16172421")
      expect(page).to have_content("2020-10-08 16:17:01")
    end
  end
end
