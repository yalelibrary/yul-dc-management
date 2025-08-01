# frozen_string_literal: true
require 'rails_helper'

RSpec.describe BatchProcess, type: :system, prep_metadata_sources: true, prep_admin_sets: true, js: true do
  let(:user) { FactoryBot.create(:user) }
  let(:admin_set) { FactoryBot.create(:admin_set, key: 'brbl', label: 'brbl') }
  # parent object has two child objects
  let(:parent_object) { FactoryBot.create(:parent_object, oid: "2005512", admin_set_id: admin_set.id) }
  let(:parent_no_children) { FactoryBot.create(:parent_object, oid: "200463000", admin_set_id: admin_set.id) }
  before do
    stub_ptiffs_and_manifests
    stub_metadata_cloud("2005512")
    parent_object
    parent_no_children
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
        p_o = ParentObject.find_by(oid: parent_object.oid)
        # original values
        expect(p_o.holding).to be_nil
        expect(p_o.item).to be_nil
        expect(p_o.barcode).to eq("39002093768050")
        expect(p_o.project_identifier).to be_nil

        # perform batch update
        visit batch_processes_path
        select("Update Parent Objects")
        page.attach_file("batch_process_file", Rails.root + "spec/fixtures/csv/update_example_small.csv")
        click_button("Submit")
        expect(page).to have_content "Your job is queued for processing in the background"

        # updated values
        p_o_a = ParentObject.find_by(oid: parent_object.oid)
        expect(p_o_a.holding).to eq("temporary")
        expect(p_o_a.item).to eq("reel")
        expect(p_o_a.barcode).to eq("39002102340669")
        expect(p_o_a.project_identifier).to eq("Beinecke")
        expect(p_o_a.digitization_funding_source).to eq("This is the Digitization Funding Source")
        visit "/batch_processes/#{BatchProcess.last.id}/parent_objects/2005512"
        expect(page).to have_content "Status Complete"
      end

      it "updates the parent with a mms_id and manifest does not include Orbis ID" do
        visit "/parent_objects/2005512/manifest"
        expect(page.body).not_to have_content("MMS ID")
        expect(page.body).to have_content("Orbis ID")

        # perform batch update
        visit batch_processes_path
        select("Update Parent Objects")
        page.attach_file("batch_process_file", Rails.root + "spec/fixtures/csv/update_example_mms_id.csv")
        click_button("Submit")
        expect(page).to have_content "Your job is queued for processing in the background"

        visit "/parent_objects/2005512/manifest"
        expect(page.body).to have_content("MMS ID")
        expect(page.body).not_to have_content("Orbis ID")
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
        p_o = ParentObject.find_by(oid: parent_object.oid)

        # original values
        expect(p_o.holding).to be_nil
        expect(p_o.item).to be_nil
        expect(p_o.barcode).to eq("39002093768050")
        # column not present - should not update value
        expect(p_o.project_identifier).to be_nil

        # perform batch update
        visit batch_processes_path
        select("Update Parent Objects")
        page.attach_file("batch_process_file", Rails.root + "spec/fixtures/csv/update_example_invalid.csv")
        click_button("Submit")
        expect(page).to have_content "Your job is queued for processing in the background"

        # values stay the same
        expect(p_o.holding).to be_nil
        expect(p_o.item).to be_nil
        expect(p_o.barcode).to eq("39002093768050")
        expect(p_o.project_identifier).to be_nil

        visit "/batch_processes/#{BatchProcess.last.id}/parent_objects/2005512"
        expect(page).to have_content "Status Complete"

        # displays help text to user
        # rubocop:disable Layout/LineLength
        visit "/batch_processes/#{BatchProcess.last.id}"
        expect(page).to have_content "Invalid Vocabulary Parent 2005512 did not update value for Extent of Digitization. Value: some is invalid. For field Extent of Digitization please use: Completely digitizied, Partially digitizied, or leave column empty\n"
        expect(page).to have_content "Invalid Vocabulary Parent 2005512 did not update value for Viewing Hint. Value: continual is invalid. For field Display Layout / Viewing Hint please use: individuals, paged, continuous, or leave column empty\n"
        expect(page).to have_content "Invalid Vocabulary Parent 2005512 did not update value for Visibility. Value: Yale-Community is invalid. For field Visibility please use: Private, Public, Open with Permission, or Yale Community Only\n"
        expect(page).to have_content "Invalid Vocabulary Parent 2005512 did not update value for Viewing Directions. Value: upside down is invalid. For field Viewing Direction please use: left-to-right, right-to-left, top-to-bottom, bottom-to-top, or leave column empty\n"
        # rubocop:enable Layout/LineLength
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
        page.attach_file("batch_process_file", Rails.root + "spec/fixtures/csv/update_example_oid_only.csv")
        click_button("Submit")
        expect(page).to have_content "Your job is queued for processing in the background"

        visit "/batch_processes/#{BatchProcess.last.id}/parent_objects/2005512"
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

  context "with a user with edit permissions but with invalid metadata source value", solr: true do
    context "updating a batch of parent objects" do
      before do
        login_as user
        user.add_role(:editor, admin_set)
      end

      it "triggers a metadata update" do
        # perform batch update
        visit batch_processes_path
        select("Update Parent Objects")
        page.attach_file("batch_process_file", Rails.root + "spec/fixtures/csv/update_example_invalid_source.csv")
        click_button("Submit")

        visit "/batch_processes/#{BatchProcess.last.id}/"
        expect(page).to have_content "View Messages"
        expect(page).to have_content "Skipping row [2] with unknown metadata source: bird. Accepted values are 'ladybird', 'aspace', 'sierra', or 'ils'."
      end
    end
  end

  context "with a user with edit permissions but with a redirect with correct format", solr: true do
    context "updating a batch of parent objects" do
      before do
        login_as user
        user.add_role(:editor, admin_set)
        parent_no_children
      end

      it "does trigger a metadata update" do
        p_o = ParentObject.find_by(oid: parent_no_children.oid)
        # original values
        expect(p_o.redirect_to).to be_nil
        # perform batch update
        visit batch_processes_path
        select("Update Parent Objects")
        page.attach_file("batch_process_file", Rails.root + "spec/fixtures/csv/update_example_redirect.csv")
        click_button("Submit")

        # updated values
        p_o_a = ParentObject.find_by(oid: parent_no_children.oid)
        expect(p_o_a.redirect_to).to eq("https://collections-uat.library.yale.edu/catalog/234567")
        expect(p_o_a.visibility).to eq("Redirect")

        visit "/batch_processes/#{BatchProcess.last.id}/"
        expect(page).to have_content "Batch complete"
      end
    end
  end

  context "with a user with edit permissions but with a redirect with incorrect format", solr: true do
    context "updating a batch of parent objects" do
      before do
        login_as user
        user.add_role(:editor, admin_set)
      end

      it "does not trigger a metadata update" do
        # perform batch update
        visit batch_processes_path
        select("Update Parent Objects")
        page.attach_file("batch_process_file", Rails.root + "spec/fixtures/csv/update_example_redirect_invalid.csv")
        click_button("Submit")

        visit "/batch_processes/#{BatchProcess.last.id}/"
        expect(page).to have_content "View Messages"
        expect(page).to have_content "Skipping row with redirect to: https://collective-uat.library.yale.edu/catalog/234567. Redirect to must be in format https://collections.library.yale.edu/catalog/1234567."
      end
    end
  end

  context "with a user with edit permissions but with a redirect when child objects are present", solr: true do
    context "updating a batch of parent objects" do
      before do
        login_as user
        user.add_role(:editor, admin_set)
      end

      it "does not trigger a metadata update" do
        # perform batch update
        visit batch_processes_path
        select("Update Parent Objects")
        page.attach_file("batch_process_file", Rails.root + "spec/fixtures/csv/update_example_redirect_with_children.csv")
        click_button("Submit")

        visit "/batch_processes/#{BatchProcess.last.id}/"
        expect(page).to have_content "View Messages"
        expect(page).to have_content "Skipped Row Skipping row with parent oid: 2005512 Child objects are attached to parent object. Parent must have no children to be redirected."
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
        page.attach_file("batch_process_file", Rails.root + "spec/fixtures/csv/update_example_small.csv")
        click_button("Submit")
        visit "/batch_processes/#{BatchProcess.last.id}"
        expect(page).to have_content "Permission Denied Skipping row [2] with parent oid: 2005512, user does not have permission to update."
      end
    end
  end
end
