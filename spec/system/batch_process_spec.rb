# frozen_string_literal: true
require 'rails_helper'

RSpec.describe BatchProcess, type: :system, prep_metadata_sources: true, prep_admin_sets: true, js: true do
  let(:user) { FactoryBot.create(:sysadmin_user) }

  around do |example|
    original_path = ENV["GOOBI_MOUNT"]
    ENV["GOOBI_MOUNT"] = File.join("spec", "fixtures", "goobi", "metadata")
    original_path_ocr = ENV['OCR_DOWNLOAD_BUCKET']
    ENV['OCR_DOWNLOAD_BUCKET'] = "yul-dc-ocr-test"
    example.run
    ENV["GOOBI_MOUNT"] = original_path
    ENV['OCR_DOWNLOAD_BUCKET'] = original_path_ocr
  end

  before do
    stub_ptiffs_and_manifests
    stub_metadata_cloud("2034600")
    stub_metadata_cloud("2005512")
    stub_metadata_cloud("16414889")
    stub_metadata_cloud("14716192")
    stub_metadata_cloud("16854285")
    stub_full_text('1030368')
    stub_full_text('1032318')
    login_as user
    visit batch_processes_path
    select("Create Parent Objects")
  end

  context "when uploading a csv" do
    it "uploads and increases csv count and gives a success message" do
      expect(BatchProcess.count).to eq 0
      page.attach_file("batch_process_file", Rails.root + "spec/fixtures/csv/short_fixture_ids.csv")
      click_button("Submit")
      expect(BatchProcess.count).to eq 1
      expect(page).to have_content("Your job is queued for processing in the background")
      expect(BatchProcess.last.file_name).to eq "short_fixture_ids.csv"
      expect(BatchProcess.last.batch_action).to eq "create parent objects"
      expect(BatchProcess.last.child_output_csv).to be nil
    end

    it "does not create batch if error saving" do
      expect(BatchProcess.count).to eq 0
      # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(BatchProcess).to receive(:save).and_return(false)
      # rubocop:enable RSpec/AnyInstance
      page.attach_file("batch_process_file", Rails.root + "spec/fixtures/csv/short_fixture_ids.csv")
      click_button("Submit")
      expect(BatchProcess.count).to eq 0
      expect(page).not_to have_content("Your job is queued for processing in the background")
    end

    it "errors batch if CSV contains too many entries" do
      expect(BatchProcess.count).to eq 0
      stub_const("BatchProcess::CSV_MAXIMUM_ENTRIES", 1)
      page.attach_file("batch_process_file", Rails.root + "spec/fixtures/csv/short_fixture_ids.csv")
      click_button("Submit")
      expect(BatchProcess.count).to eq 1
      expect(page).to have_content("Your job is queued for processing in the background")
      expect(BatchProcess.last.batch_connections.last.ingest_events.first.status).to eq 'error'
      expect(BatchProcess.last.batch_connections.last.ingest_events.first.reason).to start_with 'CSV contains'
    end

    context "re-associating child objects" do
      let(:admin_set) { FactoryBot.create(:admin_set) }
      let(:role) { FactoryBot.create(:role, name: editor) }
      let(:parent_object) { FactoryBot.create(:parent_object, oid: "2002826", admin_set_id: admin_set.id) }
      let(:parent_object_old_one) { FactoryBot.create(:parent_object, oid: "2004548", admin_set_id: admin_set.id) }
      let(:parent_object_old_two) { FactoryBot.create(:parent_object, oid: "2004549", admin_set_id: admin_set.id) }

      around do |example|
        perform_enqueued_jobs do
          example.run
        end
      end
      before do
        stub_metadata_cloud("2002826")
        stub_metadata_cloud("2004548")
        stub_metadata_cloud("2004549")
        parent_object
        parent_object_old_one
        parent_object_old_two
        user.add_role(:editor, admin_set)
      end

      it "uploads a CSV of child oids in order to re-associate them with new parent oids" do
        expect(BatchProcess.count).to eq 0
        page.attach_file("batch_process_file", Rails.root + "spec/fixtures/csv/reassociation_example_small.csv")
        select("Reassociate Child Oids")
        click_button("Submit")
        expect(BatchProcess.count).to eq 1
        expect(page).to have_content("Your job is queued for processing in the background")
      end

      it "displays children in batch parent details" do
        expect(ChildObject.find_by_oid(1_021_925).parent_object.oid).to eq(2_004_548)
        page.attach_file("batch_process_file", Rails.root + "spec/fixtures/csv/reassociation_example_small.csv")
        select("Reassociate Child Oids")
        click_button("Submit")
        expect(page).to have_content("Your job is queued for processing in the background")
        click_link(BatchProcess.last.id.to_s)
        expect(page).to have_link("2002826")
        click_link("2002826")
        expect(page).to have_link("1021925")
        click_link("1021925")
        expect(page).to have_content("Child Batch Process Detail")
        expect(ChildObject.find_by_oid(1_021_925).parent_object.oid).to eq(2_002_826)
      end

      it "displays batch messages on batch show" do
        page.attach_file("batch_process_file", Rails.root + "spec/fixtures/csv/reassociation_example_small.csv")
        select("Reassociate Child Oids")
        click_button("Submit")
        expect(page).to have_content("Your job is queued for processing in the background")
        click_link(BatchProcess.last.id.to_s)
        expect(page).to have_content("Batch Messages")
        expect(page).to have_content("Skipped Row").twice
      end

      it "displays batch messages for invalid order" do
        page.attach_file("batch_process_file", Rails.root + "spec/fixtures/csv/reassociation_example_invalid_order.csv")
        select("Reassociate Child Oids")
        click_button("Submit")
        expect(page).to have_content("Your job is queued for processing in the background")
        click_link(BatchProcess.last.id.to_s)
        expect(page).to have_content("Batch Messages")
        expect(page).to have_content("Skipped Row").once
        expect(page).to have_content("invalid order").once
      end

      it "updates all parent object counts" do
        page.attach_file("batch_process_file", Rails.root + "spec/fixtures/csv/reassociation_example_child_object_counts.csv")
        select("Reassociate Child Oids")
        click_button("Submit")
        expect(page).to have_content("Your job is queued for processing in the background")
        expect(parent_object.reload.child_objects.count).to eq(0)
        expect(parent_object_old_one.reload.child_object_count).to eq(3)
      end

      it "does not update label, caption, or order if not in csv" do
        co = ChildObject.find(1_011_398)
        co.label = "TEST LABEL STAY SAME"
        co.caption = "TEST LABEL STAY SAME2"
        co.order = 3_445_234
        co.save
        page.attach_file("batch_process_file", Rails.root + "spec/fixtures/csv/reassociation_example_missing_column.csv")
        select("Reassociate Child Oids")
        click_button("Submit")
        expect(page).to have_content("Your job is queued for processing in the background")
        expect(co.reload.label).to eq("TEST LABEL STAY SAME")
        expect(co.caption).to eq("TEST LABEL STAY SAME2")
        expect(co.order).to eq(3_445_234)
      end
    end

    context "outputting csv" do
      let(:brbl) { AdminSet.find_by_key("brbl") }
      let(:other_admin_set) { FactoryBot.create(:admin_set) }
      let(:parent_object) { FactoryBot.create(:parent_object, oid: 2_034_600, admin_set: brbl, digital_object_source: "Preservica", preservica_uri: "/preservica_uri") }
      let(:parent_object2) { FactoryBot.create(:parent_object, oid: 2_005_512, admin_set: other_admin_set) }
      let(:parent_object3) { FactoryBot.create(:parent_object, oid: 2_004_548, admin_set: brbl) }
      let(:user) { FactoryBot.create(:user) }

      before do
        stub_metadata_cloud("2004548")
        user.add_role(:viewer, brbl)
        login_as user
        parent_object
        parent_object2
        parent_object3
      end

      around do |example|
        perform_enqueued_jobs do
          example.run
        end
      end

      it "uploads a CSV of admin set in order to create export of parent object oids" do
        expect(BatchProcess.count).to eq 0
        page.attach_file("batch_process_file", Rails.root + "spec/fixtures/csv/export_parent_oids.csv")
        select("Export All Parent Objects By Admin Set")
        click_button("Submit")
        expect(BatchProcess.count).to eq 1
        expect(page).to have_content("Your job is queued for processing in the background")
        expect(BatchProcess.last.file_name).to eq "export_parent_oids.csv"
        expect(BatchProcess.last.batch_action).to eq "export all parent objects by admin set"
        expect(BatchProcess.last.parent_output_csv).to include "2034600"
        expect(BatchProcess.last.parent_output_csv).to include "Preservica"
        expect(BatchProcess.last.parent_output_csv).to include "/preservica_uri"
        expect(BatchProcess.last.parent_output_csv).not_to include "2005512"
      end

      it "uploads a CSV of parent oids in order to create export of child objects oids and orders" do
        expect(BatchProcess.count).to eq 0
        page.attach_file("batch_process_file", Rails.root + "spec/fixtures/csv/sample_fixture_ids.csv")
        select("Export Child Oids")
        click_button("Submit")
        expect(BatchProcess.count).to eq 1
        expect(page).to have_content("Your job is queued for processing in the background")
        expect(BatchProcess.last.file_name).to eq "sample_fixture_ids.csv"
        expect(BatchProcess.last.batch_action).to eq "export child oids"
        expect(BatchProcess.last.child_output_csv).to include "1021925"
        expect(BatchProcess.last.child_output_csv).to include "JWJ MSS 49"
        expect(BatchProcess.last.child_output_csv).to include '2005512,,0,Access denied for parent object,"",""'
        expect(BatchProcess.last.child_output_csv).not_to include "1030368" # child of 2005512
        expect(BatchProcess.last.batch_ingest_events.count).to eq 9
        expect(BatchProcess.last.batch_ingest_events.map(&:reason)).to include "Skipping row [3] due to parent permissions: 2005512"

        sorted_child_objects = BatchProcess.last.sorted_child_objects
        expect(sorted_child_objects[0]).to be_a(ChildObject)
        expect(sorted_child_objects[1]).to be_a(ChildObject)
        expect(sorted_child_objects[2]).to include 2_005_512
        expect(sorted_child_objects[3]).to include 14_716_192
        expect(sorted_child_objects[4]).to include 16_414_889

        within("td:first-child") do
          click_on(BatchProcess.last.id.to_s)
        end
        expect(page).to have_link("sample_fixture_ids.csv", href: "/batch_processes/#{BatchProcess.last.id}/download")
        expect(page).to have_link("sample_fixture_ids_bp_#{BatchProcess.last.id}.csv")
        bp = BatchProcess.last
        expect(bp.oids).to eq ["2004548", "2005512", "16414889", "14716192", "16854285"]
        click_on("sample_fixture_ids_bp_#{BatchProcess.last.id}.csv")
        File.delete("./sample_fixture_ids_bp_#{BatchProcess.last.id}.csv") if File.exist?("./sample_fixture_ids_bp_#{BatchProcess.last.id}.csv")
      end

      context "round-tripping csv" do
        it "can create the output csv from a csv that has been generated from the application" do
          page.attach_file("batch_process_file", Rails.root + "spec/fixtures/csv/parents_for_reassociation_as_output.csv")
          select("Export Child Oids")
          click_button("Submit")
          expect(BatchProcess.count).to eq 1
          expect(page).to have_content("Your job is queued for processing in the background")
          bp = BatchProcess.last
          expect(bp.oids).to eq ["2002826", "2004548", "2004549"]
        end

        it "can create the output csv from a handmade csv" do
          page.attach_file("batch_process_file", Rails.root + "spec/fixtures/csv/parents_for_reassociation.csv")
          select("Export Child Oids")
          click_button("Submit")
          expect(BatchProcess.count).to eq 1
          expect(page).to have_content("Your job is queued for processing in the background")
          bp = BatchProcess.last
          expect(bp.oids).to eq ["2002826", "2004548", "2004549"]
        end
      end
    end

    context "deleting a parent object" do
      around do |example|
        perform_enqueued_jobs do
          example.run
        end
      end
      before do
        page.attach_file("batch_process_file", Rails.root + "spec/fixtures/csv/short_fixture_ids.csv")
        click_button("Submit")
        po = ParentObject.find(16_854_285)
        po.destroy
        page.refresh
      end

      it "can still see the details of the import" do
        expect(page).to have_link(BatchProcess.last.id.to_s, href: "/batch_processes/#{BatchProcess.last.id}")
        expect(page).to have_content('5')
        expect(page).to have_link(BatchProcess.last.id.to_s, href: "/batch_processes/#{BatchProcess.last.id}")
      end
    end

    context "re-generate ptiffs child objects" do
      let(:parent_object) { FactoryBot.create(:parent_object, oid: "2002826") }

      around do |example|
        perform_enqueued_jobs do
          example.run
        end
      end
      before do
        stub_metadata_cloud("2002826")
        parent_object
      end
      it "displays children in batch parent details" do
        page.attach_file("batch_process_file", Rails.root + "spec/fixtures/csv/recreate_child_ptiffs.csv")
        select("Recreate Child Oid Ptiffs")
        click_button("Submit")
        expect(page).to have_content("Your job is queued for processing in the background")
        click_link(BatchProcess.last.id.to_s)
        expect(page).to have_link("2002826")
        click_link("2002826")
        expect(page).to have_link("1011398")
        click_link("1011398")
        expect(page).to have_content("Child Batch Process Detail")
      end
      it "displays batch messages on batch details" do
        page.attach_file("batch_process_file", Rails.root + "spec/fixtures/csv/recreate_child_ptiffs.csv")
        select("Recreate Child Oid Ptiffs")
        click_button("Submit")
        expect(page).to have_content("Your job is queued for processing in the background")
        click_link(BatchProcess.last.id.to_s)
        expect(page).to have_content("Batch Messages")
        expect(page).to have_content("Skipped Row")
      end
    end
  end
  context "when uploading an xml" do
    it "uploads and increases xml count and gives a success message" do
      expect(BatchProcess.count).to eq 0
      page.attach_file("batch_process_file", fixture_path + '/goobi/metadata/30000317_20201203_140947/111860A_8394689_mets.xml')
      click_button("Submit")
      expect(BatchProcess.count).to eq 1
      expect(page).to have_content("Your job is queued for processing in the background")
      expect(BatchProcess.last.file_name).to eq "111860A_8394689_mets.xml"
    end

    context "deleting a parent object" do
      before do
        page.attach_file("batch_process_file", fixture_path + '/goobi/metadata/30000317_20201203_140947/111860A_8394689_mets.xml')
        click_button("Submit")
      end
      it "can still load the batch_process page" do
        po = ParentObject.find(30_000_317)
        po.delete
        expect(po.destroyed?).to be true
        visit batch_processes_path
        click_on(BatchProcess.last.id.to_s)
        expect(page.body).to have_link(BatchProcess.last.id.to_s, href: "/batch_processes/#{BatchProcess.last.id}")
      end
    end
  end

  context "when uploading an xml with jobs running" do
    let(:logger_mock) { instance_double("Rails.logger").as_null_object }

    before do
      logger_mock
    end

    around do |example|
      perform_enqueued_jobs do
        example.run
      end
    end

    it "create preservica ingest for the parent and children objects" do
      # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(SetupMetadataJob).to receive(:check_mets_images).and_return(true)
      allow_any_instance_of(ParentObject).to receive(:default_fetch).and_return(true)
      # rubocop:enable RSpec/AnyInstance check_mets_images
      expect(BatchProcess.count).to eq 0
      page.attach_file("batch_process_file", fixture_path + '/goobi/metadata/30000317_20201203_140947/111860A_8394689_mets.xml')
      click_button("Submit")
      pj = PreservicaIngest.find_by_child_oid(30_000_319)
      expect(pj.preservica_child_id).to eq "1234d3360-bf78-4e35-9850-44ef7f832100"
      expect(pj.preservica_id).to eq "b9afab50-9f22-4505-ada6-807dd7d05733"
    end

    it "does not create preservica ingest if no parent uuid" do
      # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(SetupMetadataJob).to receive(:check_mets_images).and_return(true)
      allow_any_instance_of(ParentObject).to receive(:default_fetch).and_return(true)
      # rubocop:enable RSpec/AnyInstance check_mets_images
      expect(BatchProcess.count).to eq 0
      page.attach_file("batch_process_file", fixture_path + '/goobi/metadata/30000317_20201203_140947/no_uuid.xml')
      click_button("Submit")
      pj = PreservicaIngest.find_by_child_oid(30_000_322)
      expect(pj.nil?).to be_truthy
      pj_parent = PreservicaIngest.find_by_parent_oid(30_000_321)
      expect(pj_parent.nil?).to be_truthy
    end
  end

  it "triggers directory scan" do
    visit batch_processes_path
    expect(MetsDirectoryScanJob).to receive(:perform_later).and_return(nil).once
    click_on("Start Goobi Scan")
    expect(page.driver.browser.switch_to.alert.text).to eq("Are you sure you start a Goobi Scan?")
    page.driver.browser.switch_to.alert.accept
    expect(page).to have_content("Mets scan has been triggered.")
  end

  context "when logged in without sysadmin privileges" do
    let(:user) { FactoryBot.create(:user) }
    before do
      login_as user
      visit batch_processes_path
    end

    it "triggers directory scan is disabled" do
      expect(page).to have_button('Start Goobi Scan', disabled: true)
    end
  end

  context "batch processes page", js: true do
    let(:user) { FactoryBot.create(:user) }
    before do
      login_as user
      visit batch_processes_path
    end

    it "has csv button" do
      expect(page).to have_css(".buttons-csv")
    end

    it "has excel button" do
      expect(page).to have_css(".buttons-excel")
    end

    it "has column visibility button" do
      expect(page).to have_css(".buttons-colvis")
    end
  end
end
