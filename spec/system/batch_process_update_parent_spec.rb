# frozen_string_literal: true
require 'rails_helper'

RSpec.describe BatchProcess, type: :system, prep_metadata_sources: true, prep_admin_sets: true, js: true do
  let(:user) { FactoryBot.create(:user) }
  let(:admin_set) { FactoryBot.create(:admin_set, key: 'brbl', label: 'brbl') }
  # parent object has four child objects
  let!(:parent_object) { FactoryBot.create(:parent_object, oid: "2034600", admin_set_id: admin_set.id) }

  before do
    stub_ptiffs_and_manifests
    stub_metadata_cloud("2034600")
  end

  around do |example|
    perform_enqueued_jobs do
      original_path_ocr = ENV['OCR_DOWNLOAD_BUCKET']
      ENV['OCR_DOWNLOAD_BUCKET'] = "yul-dc-ocr-test"
      example.run
      ENV['OCR_DOWNLOAD_BUCKET'] = original_path_ocr
    end
  end

  context "with a user with edit permissions and valid controlled vocabulary", solr: true do
    context "updating a batch of parent objects" do
      before do
        login_as user
        user.add_role(:editor, admin_set)
      end

      it "updates the parent" do
        visit "/parent_objects/#{parent_object.oid}"
        # original values
        expect(page).to have_content("Holding:\n")
        expect(page).to have_content("Item:\n")
        expect(page).to have_content("Barcode:\n")
        expect(page).to have_content("Aspace uri:\n")
        expect(page).to have_content("Visibility: Public\n")
        expect(page).to have_content("Rights Statement:\n")
        expect(page).to have_content("Extent of Digitization: Partially digitized\n")
        expect(page).to have_content("Digitization Note:\n")
        expect(page).to have_content("Viewing Direction:\n")
        expect(page).to have_content("Display Layout / Viewing Hint:\n")

        # perform batch update
        visit batch_processes_path
        select("Update Parent Objects")
        page.attach_file("batch_process_file", Rails.root + "spec/fixtures/update_example_small.csv")
        click_button("Submit")
        expect(page).to have_content "Your job is queued for processing in the background"

        visit "/parent_objects/#{parent_object.oid}"
        expect(page).to have_content("Holding: temporary")
        expect(page).to have_content("Item: reel")
        expect(page).to have_content("Barcode: 39002102340669")
        expect(page).to have_content("Aspace uri: /repositories/11/archival_objects/515305")
        expect(page).to have_content("Visibility: Public")
        expect(page).to have_content("Rights Statement:\nThe use of this image may be subject to the copyright law of the United States")
        expect(page).to have_content("Extent of Digitization: Completely digitized")
        expect(page).to have_content("Digitization Note: 5678")
        expect(page).to have_content("Viewing Direction: left-to-right")
        expect(page).to have_content("Display Layout / Viewing Hint: paged")

        visit "/batch_processes/#{BatchProcess.last.id}/parent_objects/2034600"
        expect(page).to have_content "Status Complete"
      end
    end
  end

  context "with a user with edit permissions but without valid controlled vocabulary", solr: true do
    context "updating a batch of parent objects" do
      before do
        login_as user
        user.add_role(:editor, admin_set)
      end

      it "does not update the parent with invalid values" do
        visit "/parent_objects/#{parent_object.oid}"
        # original values
        expect(page).to have_content("Extent of Digitization: Partially digitized\n")
        expect(page).to have_content("Visibility: Public\n")
        expect(page).to have_content("Viewing Direction:\n")
        expect(page).to have_content("Display Layout / Viewing Hint:\n")

        # perform batch update
        visit batch_processes_path
        select("Update Parent Objects")
        page.attach_file("batch_process_file", Rails.root + "spec/fixtures/update_example_invalid.csv")
        click_button("Submit")
        expect(page).to have_content "Your job is queued for processing in the background"

        visit "/parent_objects/#{parent_object.oid}"
        expect(page).to have_content("Extent of Digitization: Partially digitized")
        expect(page).to have_content("Visibility: Public\n")
        expect(page).to have_content("Viewing Direction:\n")
        expect(page).to have_content("Display Layout / Viewing Hint:\n")

        visit "/batch_processes/#{BatchProcess.last.id}/parent_objects/2034600"
        expect(page).to have_content "Status Complete"

        # displays help text to user
        # rubocop:disable Metrics/LineLength
        visit "/batch_processes/#{BatchProcess.last.id}"
        expect(page).to have_content "Invalid Vocabulary Parent 2034600 did not update value for Extent of Digitization. Value: some is invalid. For field Extent of Digitization please use: Completely digitizied, Partially digitizied, or leave column empty\n"
        expect(page).to have_content "Invalid Vocabulary Parent 2034600 did not update value for Viewing Hint. Value: continual is invalid. For field Display Layout / Viewing Hint please use: individuals, paged, continuous, or leave column empty\n"
        expect(page).to have_content "Invalid Vocabulary Parent 2034600 did not update value for Visibility. Value: Yale-Community is invalid. For field Visibility please use: Private, Public, or Yale Community Only\n"
        expect(page).to have_content "Invalid Vocabulary Parent 2034600 did not update value for Viewing Directions. Value: upside down is invalid. For field Viewing Direction please use: left-to-right, right-to-left, top-to-bottom, bottom-to-top, or leave column empty\n"
        # rubocop:enable Metrics/LineLength
      end
    end
  end

  context "with a user with edit permissions but with only an oid value", solr: true do
    context "updating a batch of parent objects" do
      before do
        login_as user
        user.add_role(:editor, admin_set)
      end

      it "triggers a metadata update" do
        today = Time.zone.today
        # perform batch update
        visit batch_processes_path
        select("Update Parent Objects")
        page.attach_file("batch_process_file", Rails.root + "spec/fixtures/update_example_oid_only.csv")
        click_button("Submit")
        expect(page).to have_content "Your job is queued for processing in the background"

        visit "/batch_processes/#{BatchProcess.last.id}/parent_objects/2034600"
        expect(page).to have_content "Status Complete"

        expect(page).to have_content "Submitted #{today}"
        expect(page).to have_content "Processing Queued Pending"
        expect(page).to have_content "Metadata Fetched #{today}"
        expect(page).to have_content "Child Records Created #{today}"
        expect(page).to have_content "Manifest Saved #{today}"
        expect(page).to have_content "Solr Indexed #{today}"
        expect(page).to have_content "PDF Generated #{today}"
      end
    end
  end

  context "with a user without edit permissions" do
    let(:admin_user) { FactoryBot.create(:sysadmin_user) }

    context "updating a batch of parent objects" do
      before do
        login_as admin_user
        admin_user.remove_role(:editor)
        visit batch_processes_path
      end

      it "does not permit parent to be updated" do
        select("Update Parent Objects")
        page.attach_file("batch_process_file", Rails.root + "spec/fixtures/update_example_small.csv")
        click_button("Submit")
        visit "/batch_processes/#{BatchProcess.last.id}"
        expect(page).to have_content "Permission Denied Skipping row [2] with parent oid: 2034600, user does not have permission to update."
      end
    end
  end
end