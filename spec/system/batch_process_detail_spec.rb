# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "Batch Process detail page", type: :system, prep_metadata_sources: true, js: true do
  let(:user) { FactoryBot.create(:user, uid: "johnsmith2530") }
  before do
    stub_ptiffs_and_manifests
    stub_metadata_cloud("2004628")
    stub_metadata_cloud("2030006")
    stub_metadata_cloud("2034600")
    stub_metadata_cloud("16057779")
    stub_metadata_cloud("15234629")
    login_as user
    visit batch_process_path(batch_process)
  end

  context "when uploading a csv" do
    around do |example|
      perform_enqueued_jobs do
        example.run
      end
    end
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

    context "when batch wide ingest event is available" do
      let(:ingest_event) do
        IngestEvent.create(
          reason: "This is the batch event",
          status: "Batch event statue"
        )
      end

      before do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(BatchProcess).to receive(:batch_ingest_events).and_return([ingest_event])
        # rubocop:enable RSpec/AnyInstance
        visit batch_process_path(batch_process)
      end

      it "can see the ingest events of the import" do
        expect(page).to have_content(batch_process.id.to_s)
        expect(page).to have_content(ingest_event.reason)
      end
    end

    it "can see the status of the parent object imports" do
      expect(page).to have_content("Batch complete")
    end

    it "can see the overall status of the batch process" do
      expect(batch_process.batch_status).to eq "Batch complete"
      expect(page).to have_content("Batch complete")
    end

    context "deleting a parent object" do
      before do
        batch_process
        visit batch_process_path(batch_process)
        po = ParentObject.find(16_057_779)
        po.run_callbacks :destroy
        po.destroy
        page.refresh
      end

      it "can still see the details of the import" do
        expect(page).to have_content(batch_process.id.to_s)
        expect(page).to have_content('16057779')
        expect(page).to have_content('pending, or parent deleted')
        # expect(page).to have_content('Parent object deleted')
      end
    end
  end

  context "when uploading an xml doc" do
    let(:batch_process) do
      FactoryBot.create(
        :batch_process,
        user: user,
        mets_xml: File.open(fixture_path + '/goobi/metadata/30000317_20201203_140947/111860A_8394689_mets.xml').read,
        file_name: "111860A_8394689_mets.xml",
        created_at: "2020-10-08 16:17:01"
      )
    end
    it "can see the details of the import" do
      expect(page).to have_content(batch_process.id.to_s)
      expect(page).to have_content("johnsmith2530")
      expect(page).to have_link("111860A_8394689_mets.xml", href: "/batch_processes/#{batch_process.id}/download")
      expect(page).to have_link('30000317', href: "/batch_processes/#{batch_process.id}/parent_objects/30000317")
      expect(page).to have_content("2020-10-08 16:17:01")
    end
  end

  context "when uploading an xml doc without intranda information" do
    let(:batch_process) do
      FactoryBot.create(
        :batch_process,
        user: user,
        mets_xml: File.open(fixture_path + '/goobi/metadata/30000317_20201203_140947/no_intranda_namespace_mets.xml').read,
        file_name: "111860A_8394689_no_intranda_mets.xml",
        created_at: "2020-10-08 16:17:01"
      )
    end
    it "can see the details of the import" do
      expect(page).to have_content(batch_process.id.to_s)
      expect(page).to have_content("johnsmith2530")
      expect(page).to have_link("111860A_8394689_no_intranda_mets.xml", href: "/batch_processes/#{batch_process.id}/download")
      expect(page).to have_link('30001317', href: "/batch_processes/#{batch_process.id}/parent_objects/30001317")
      expect(page).to have_content("2020-10-08 16:17:01")
      expect(ParentObject.find_by_oid(30_001_317).viewing_direction).to be_nil
      expect(ParentObject.find_by_oid(30_001_317).display_layout).to be_nil
    end
  end
end
