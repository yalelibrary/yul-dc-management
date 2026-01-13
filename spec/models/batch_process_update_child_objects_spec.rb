# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BatchProcess, type: :model, prep_metadata_sources: true do
  subject(:caption_label_batch_process) { described_class.new(batch_action: "update child objects caption and label") }
  subject(:checksum_batch_process) { described_class.new(batch_action: "update child objects checksum") }
  let(:user) { FactoryBot.create(:user, uid: "mk2525") }
  let(:admin_set) { FactoryBot.create(:admin_set) }
  let(:role) { FactoryBot.create(:role, name: editor) }
  let(:caption_label_csv_upload) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "update_child_object_caption.csv")) }
  let(:caption_label_csv_blank_value_upload) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "update_child_object_blank.csv")) }
  let(:checksum_csv_valid_upload) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "checksum_child_object_valid.csv")) }
  let(:checksum_csv_invalid_upload) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "checksum_child_object_invalid.csv")) }
  let(:checksum_csv_blank_value_upload) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "checksum_child_object_blank.csv")) }
  let(:parent_object) { FactoryBot.create(:parent_object, oid: 2_002_826, admin_set_id: admin_set.id) }
  let(:initial_fixity_value) { FFaker::Number.number(digits: 20) }
  let(:tif_sha512_fixity_value) { "ddfcbb8f70ba901e979acbe0c5a716e2cb1784dae560ea396471a277caa4ce58f796adb6d64cbbdb3be3d2a2c436bc26c45b878e33a7f083c3b72272e01595b0" }
  let(:child_object) { FactoryBot.create(:child_object, oid: 10_736_292, caption: "caption", label: "label", parent_object: parent_object, sha512_checksum: initial_fixity_value) }
  let(:child_object_2) { FactoryBot.create(:child_object, oid: 67_890, caption: "co2 caption", label: "co2 label", parent_object: parent_object, sha512_checksum: initial_fixity_value) }
  let(:child_object_3) { FactoryBot.create(:child_object, oid: 12, caption: "co3 caption", label: "co3 label", parent_object: parent_object, sha512_checksum: initial_fixity_value) }

  around do |example|
    perform_enqueued_jobs do
      original_path_ocr = ENV['OCR_DOWNLOAD_BUCKET']
      access_host = ENV['ACCESS_PRIMARY_MOUNT']
      ENV['OCR_DOWNLOAD_BUCKET'] = "yul-dc-ocr-test"
      ENV['ACCESS_PRIMARY_MOUNT'] = File.join("spec", "fixtures", "images", "access_primaries")
      example.run
      ENV['OCR_DOWNLOAD_BUCKET'] = original_path_ocr
      ENV['ACCESS_PRIMARY_MOUNT'] = access_host
    end
  end

  before do
    stub_metadata_cloud("2002826")
    stub_metadata_cloud("2004548")
    stub_ptiffs_and_manifests
    parent_object
    child_object
    child_object_2
    child_object_3
    login_as(:user)
  end

  describe "batch process for update child objects caption and label" do
    describe "updating child object as a user with an editor role" do
      before do
        user.add_role(:editor, admin_set)
        caption_label_batch_process.user_id = user.id
      end

      with_versioning do
        it "can update child caption and label based on csv import" do
          expect(child_object.caption).to eq "caption"
          expect(child_object.label).to eq "label"
          expect(child_object_2.caption).to eq "co2 caption"
          expect(child_object_2.label).to eq "co2 label"
          expect(child_object_3.caption).to eq "co3 caption"
          expect(child_object_3.label).to eq "co3 label"
          caption_label_batch_process.file = caption_label_csv_upload
          caption_label_batch_process.save
          updated_child_object = ChildObject.find(10_736_292)
          updated_child_object_two = ChildObject.find(67_890)
          updated_child_object_three = ChildObject.find(12)
          expect(updated_child_object.caption).to eq "caption 2"
          expect(updated_child_object.label).to eq "label 2"
          expect(updated_child_object_two.caption).to eq "new caption"
          expect(updated_child_object_two.label).to eq "new label"
          expect(updated_child_object_three.caption).to eq "another caption"
          expect(updated_child_object_three.label).to eq "another label"
        end

        it "can update child caption and label with _blank_ values" do
          expect(child_object_2.caption).to eq "co2 caption"
          expect(child_object_2.label).to eq "co2 label"
          caption_label_batch_process.file = caption_label_csv_blank_value_upload
          caption_label_batch_process.save
          updated_child_object_two = ChildObject.find(67_890)
          expect(updated_child_object_two.caption).to eq nil
          expect(updated_child_object_two.label).to eq "label"
        end
      end
    end

    describe "updating child object as a user without an editor role" do
      before do
        user.add_role(:viewer, admin_set)
        caption_label_batch_process.user_id = user.id
        caption_label_batch_process.file = caption_label_csv_upload
        caption_label_batch_process.save
      end

      with_versioning do
        it "can't update child objects caption and label based on csv import" do
          child_object = ChildObject.find(10_736_292)
          expect(child_object.caption).to eq "caption"
          expect(child_object.label).to eq "label"
        end
      end
    end
  end

  describe "batch process for update child objects checksum" do
    describe "updating child object as a user with an editor role" do
      before do
        user.add_role(:editor, admin_set)
        checksum_batch_process.user_id = user.id
      end

      with_versioning do
        it "can update child checksum based on csv import" do
          # begin test with incorrect fixity values saved to the child object
          expect(child_object.sha512_checksum).to eq initial_fixity_value.to_s
          expect(child_object_2.sha512_checksum).to eq initial_fixity_value.to_s
          expect(child_object_3.sha512_checksum).to eq initial_fixity_value.to_s
          checksum_batch_process.file = checksum_csv_valid_upload
          checksum_batch_process.save
          updated_child_object = ChildObject.find(10_736_292)
          updated_child_object_two = ChildObject.find(67_890)
          updated_child_object_three = ChildObject.find(12)
          # all tifs are the same image so matching checksums is expected
          expect(updated_child_object.sha512_checksum).to eq tif_sha512_fixity_value
          expect(updated_child_object_two.sha512_checksum).to eq tif_sha512_fixity_value
          expect(updated_child_object_three.sha512_checksum).to eq tif_sha512_fixity_value
          expect(checksum_batch_process.batch_ingest_events.count).to eq 2
          expect(checksum_batch_process.batch_ingest_events.first.reason).to eq "3 child objects updated."
          expect(checksum_batch_process.batch_ingest_events.last.reason).to eq "All child objects from csv were updated."
          expect(updated_child_object.events_for_batch_process(checksum_batch_process).count).to eq 1
          expect(updated_child_object.events_for_batch_process(checksum_batch_process).first.reason).to eq "Child 10736292 has been updated"
          expect(updated_child_object_two.events_for_batch_process(checksum_batch_process).count).to eq 1
          expect(updated_child_object_two.events_for_batch_process(checksum_batch_process).first.reason).to eq "Child 67890 has been updated"
          expect(updated_child_object_three.events_for_batch_process(checksum_batch_process).count).to eq 1
          expect(updated_child_object_three.events_for_batch_process(checksum_batch_process).first.reason).to eq "Child 12 has been updated"
        end

        # rubocop:disable Layout/LineLength
        it "cannot update child checksum with incorrect values" do
          # begin test with incorrect fixity values saved to the child object
          expect(child_object.sha512_checksum).to eq initial_fixity_value.to_s
          expect(child_object_2.sha512_checksum).to eq initial_fixity_value.to_s
          expect(child_object_3.sha512_checksum).to eq initial_fixity_value.to_s
          checksum_batch_process.file = checksum_csv_invalid_upload
          checksum_batch_process.save
          updated_child_object = ChildObject.find(10_736_292)
          updated_child_object_two = ChildObject.find(67_890)
          updated_child_object_three = ChildObject.find(12)
          # ensure child object page has message to user on what succeeded or failed
          # all tifs are the same image so matching checksums is expected
          expect(updated_child_object.sha512_checksum).to eq tif_sha512_fixity_value
          expect(updated_child_object_two.sha512_checksum).to eq tif_sha512_fixity_value
          expect(updated_child_object_three.sha512_checksum).to eq tif_sha512_fixity_value
          expect(checksum_batch_process.batch_ingest_events.count).to eq 5
          expect(checksum_batch_process.batch_ingest_events.first.reason).to eq "Child 10736292 was updated with the sha512 checksum value, read from the access primary original image file."
          expect(checksum_batch_process.batch_ingest_events[3].reason).to eq "3 child objects updated."
          expect(checksum_batch_process.batch_ingest_events.last.reason).to eq "All child objects from csv were updated."
          expect(updated_child_object.events_for_batch_process(checksum_batch_process).count).to eq 2
          expect(updated_child_object.events_for_batch_process(checksum_batch_process).first.reason).to eq "Child 10736292 was updated with the sha512 checksum value, read from the access primary original image file."
          expect(updated_child_object.events_for_batch_process(checksum_batch_process).last.reason).to eq "Child 10736292 has been updated"
          expect(updated_child_object_two.events_for_batch_process(checksum_batch_process).count).to eq 2
          expect(updated_child_object_two.events_for_batch_process(checksum_batch_process).first.reason).to eq "Child 67890 was updated with the sha512 checksum value, read from the access primary original image file."
          expect(updated_child_object_two.events_for_batch_process(checksum_batch_process).last.reason).to eq "Child 67890 has been updated"
          expect(updated_child_object_three.events_for_batch_process(checksum_batch_process).count).to eq 2
          expect(updated_child_object_three.events_for_batch_process(checksum_batch_process).first.reason).to eq "Child 12 was updated with the sha512 checksum value, read from the access primary original image file."
          expect(updated_child_object_three.events_for_batch_process(checksum_batch_process).last.reason).to eq "Child 12 has been updated"
        end
        # rubocop:enable Layout/LineLength

        it "cannot update child checksum with _blank_ values" do
          expect(child_object_2.sha512_checksum).to eq initial_fixity_value.to_s
          checksum_batch_process.file = checksum_csv_blank_value_upload
          checksum_batch_process.save
          updated_child_object_two = ChildObject.find(67_890)
          expect(updated_child_object_two.sha512_checksum).not_to eq nil
        end
      end
    end

    describe "updating child object as a user without an editor role" do
      before do
        user.add_role(:viewer, admin_set)
        checksum_batch_process.user_id = user.id
        checksum_batch_process.file = checksum_csv_valid_upload
        checksum_batch_process.save
      end

      with_versioning do
        it "can't update child objects checksum based on csv import" do
          child_object = ChildObject.find(10_736_292)
          expect(child_object.sha512_checksum).to eq initial_fixity_value.to_s
          expect(checksum_batch_process.batch_ingest_events.first.reason).to eq "Skipping row [2] with child oid: 10736292, user does not have permission to update."
          expect(checksum_batch_process.batch_ingest_events.last.reason).to eq "Child objects that were not updated: [\"10736292\", \"67890\", \"12\"]."
        end
      end
    end
  end
end
