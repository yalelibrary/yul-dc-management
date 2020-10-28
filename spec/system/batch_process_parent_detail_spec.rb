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
    stub_ptiffs_and_manifests
    login_as user
    visit show_parent_batch_process_path(batch_process, 16_057_779)
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

    it "has a link to the parent object page" do
      expect(page.body).to have_link('16057779', href: "/parent_objects/16057779")
    end

    it "has a link to the batch process detail page" do
      expect(page.body).to have_link(batch_process.id.to_s, href: "/batch_processes/#{batch_process.id}")
    end

    it "includes the notifications connected to this parent import" do
      expect(page.body).to include("Processing Queued")
      expect(page).to have_css("td.submission_time")
      st = page.find("td.submission_time").text
      expect(st.to_datetime).to be_an_instance_of DateTime
    end

    describe "after running the background jobs" do
      around do |example|
        perform_enqueued_jobs do
          example.run
        end
      end

      it "includes the child oids" do
        expect(page).to have_css("td.child_oid", text: "16057781")
      end
    end
  end
end
