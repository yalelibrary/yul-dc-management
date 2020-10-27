# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "Batch Process detail page", type: :system, prep_metadata_sources: true do
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
      expect(page.body).to include batch_process.id.to_s
      expect(page.body).to include "johnsmith2530"
      expect(page.body).to have_link("small_short_fixture_ids.csv", href: "/batch_processes/#{batch_process.id}/download")
      expect(page.body).to have_link('16057779', href: "/batch_processes/#{batch_process.id}/parent_objects/16057779")
      within all("td.child_count")[3] do
        expect(page.body).to include "4"
      end
      expect(page.body).to include "2020-10-08 14:17:01"
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
        expect(page.body).to include batch_process.id.to_s
        within all("td.parent_oid")[3] do
          expect(page.body).to have_link('16057779', href: "/batch_processes/#{batch_process.id}/parent_objects/16057779")
        end
        within all("td.child_count")[3] do
          expect(page.body).to include('(deleted)')
        end
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
      expect(page.body).to include batch_process.id.to_s
      expect(page.body).to include "johnsmith2530"
      expect(page.body).to have_link("meta.xml", href: "/batch_processes/#{batch_process.id}/download")
      within "td.parent_oid" do
        expect(page.body).to have_link('16172421', href: "/batch_processes/#{batch_process.id}/parent_objects/16172421")
      end
      expect(page.body).to include "2020-10-08 16:17:01"
    end
  end
end
