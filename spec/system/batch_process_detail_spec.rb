# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "Batch Process detail page", type: :system, prep_metadata_sources: true do
  let(:user) { FactoryBot.create(:user, uid: "johnsmith2530") }
  before do
    stub_metadata_cloud("2034600")
    stub_metadata_cloud("2005512")
    stub_metadata_cloud("16414889")
    stub_metadata_cloud("14716192")
    stub_metadata_cloud("16854285")
    login_as user
    visit batch_process_path(batch_process)
  end

  context "when uploading a csv" do
    let(:batch_process) { FactoryBot.create(:batch_process, user: user, csv: File.open(fixture_path + '/short_fixture_ids.csv').read, file_name: "short_fixture_ids.csv") }
    it "can see the details of the import" do
      expect(page.body).to include batch_process.id.to_s
      expect(page.body).to include "johnsmith2530"
      expect(page.body).to have_link("short_fixture_ids.csv", href: "/batch_processes/#{batch_process.id}/download_csv")
    end
  end
  context "when uploading an xml doc" do
    let(:batch_process) do
      FactoryBot.create(
        :batch_process,
        user: user,
        mets_xml: File.open(fixture_path + '/goobi/min_valid_xml.xml').read,
        file_name: "min_valid_xml.xml"
      )
    end
    it "can see the details of the import" do
      expect(page.body).to include batch_process.id.to_s
      expect(page.body).to include "johnsmith2530"
      expect(page.body).to have_link("min_valid_xml.xml", href: "/batch_processes/#{batch_process.id}/download_xml")
    end
  end
end
