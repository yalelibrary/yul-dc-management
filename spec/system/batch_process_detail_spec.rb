# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "Batch Process detail page", type: :system, prep_metadata_sources: true, prep_admin_sets: true, js: true do
  let(:user) { FactoryBot.create(:user, uid: "johnsmith2530") }
  let(:admin_set) { FactoryBot.create(:admin_set) }
  before do
    stub_ptiffs_and_manifests
    stub_metadata_cloud("2004628")
    stub_metadata_cloud("2030006")
    stub_metadata_cloud("2034600")
    stub_metadata_cloud("16057779")
    stub_metadata_cloud("15234629")
    login_as user
  end

  context "when uploading a csv" do
    around do |example|
      original_path_ocr = ENV['OCR_DOWNLOAD_BUCKET']
      ENV['OCR_DOWNLOAD_BUCKET'] = "yul-dc-ocr-test"
      perform_enqueued_jobs do
        example.run
      end
      ENV['OCR_DOWNLOAD_BUCKET'] = original_path_ocr
    end
    let(:batch_process) do
      FactoryBot.create(
        :batch_process,
        user: user,
        csv: File.open(fixture_path + '/csv/small_short_fixture_ids.csv').read,
        file_name: "small_short_fixture_ids.csv",
        created_at: "2020-10-08 14:17:01"
      )
    end

    let(:batch_process_bad_admin_set) do
      FactoryBot.create(
        :batch_process,
        user: user,
        csv: File.open(fixture_path + '/csv/short_fixture_bad_admin_set.csv').read,
        file_name: "short_fixture_bad_admin_set.csv",
        created_at: "2020-10-08 14:17:01"
      )
    end

    it "can see the details of the import" do
      visit batch_process_path(batch_process)
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
      visit batch_process_path(batch_process)
      expect(page).to have_content("Batch complete")
    end

    it "can see the overall status of the batch process" do
      visit batch_process_path(batch_process)
      expect(batch_process.batch_status).to eq "Batch complete"
      expect(page).to have_content("Batch complete")
    end

    it "can see the overall status of the batch process BAD admin set" do
      expect(batch_process_bad_admin_set.parent_objects.count).to eq 3
      expect(batch_process_bad_admin_set.parent_objects.first.admin_set.key).to eq "brbl"
      expect(batch_process_bad_admin_set.batch_status).to eq "Batch complete"
      visit batch_processes_path
      expect(page).to have_content("Batch complete")
      expect(page).to have_link("1", href: batch_process_path(batch_process_bad_admin_set), class: 'btn btn-warning')
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
      visit batch_process_path(batch_process)
      expect(page).to have_content(batch_process.id.to_s)
      expect(page).to have_content("johnsmith2530")
      expect(page).to have_link("111860A_8394689_mets.xml", href: "/batch_processes/#{batch_process.id}/download")
      expect(page).to have_link('30000317', href: "/batch_processes/#{batch_process.id}/parent_objects/30000317")
      expect(page).to have_content("2020-10-08 16:17:01")
    end
  end

  context "when uploading a valid alma xml doc" do
    let(:batch_process) do
      FactoryBot.create(
        :batch_process,
        user: user,
        mets_xml: File.open(fixture_path + '/goobi/metadata/30000317_20201203_140947/valid_alma_mets.xml').read,
        file_name: "valid_alma_mets.xml",
        created_at: "2025-04-23 16:17:01"
      )
    end
    it "can see the details of the import" do
      visit batch_process_path(batch_process)
      expect(page).to have_content(batch_process.id.to_s)
      expect(page).to have_content("johnsmith2530")
      expect(page).to have_link("valid_alma_mets.xml", href: "/batch_processes/#{batch_process.id}/download")
      expect(page).to have_link('800054805', href: "/batch_processes/#{batch_process.id}/parent_objects/800054805")
      expect(page).to have_content("2025-04-23 16:17:01")
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
      admin_set
      visit batch_process_path(batch_process)
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
