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
  let(:checksum_csv_upload) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "checksum_child_object.csv")) }
  let(:checksum_csv_blank_value_upload) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "checksum_child_object_blank.csv")) }
  let(:parent_object) { FactoryBot.create(:parent_object, oid: 2_002_826, admin_set_id: admin_set.id) }
  let(:initial_fixity_value) { FFaker::Number.number(digits: 20) }
  let(:child_object) { FactoryBot.create(:child_object, oid: 10_736_292, caption: "caption", label: "label", parent_object: parent_object, sha512_checksum: initial_fixity_value) }
  let(:child_object_2) { FactoryBot.create(:child_object, oid: 67_890, caption: "co2 caption", label: "co2 label", parent_object: parent_object, sha512_checksum: initial_fixity_value) }
  let(:child_object_3) { FactoryBot.create(:child_object, oid: 12, caption: "co3 caption", label: "co3 label", parent_object: parent_object, sha512_checksum: initial_fixity_value) }

  around do |example|
    perform_enqueued_jobs do
      original_path_ocr = ENV['OCR_DOWNLOAD_BUCKET']
      ENV['OCR_DOWNLOAD_BUCKET'] = "yul-dc-ocr-test"
      example.run
      ENV['OCR_DOWNLOAD_BUCKET'] = original_path_ocr
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
          expect(child_object.sha512_checksum).to eq initial_fixity_value.to_s
          expect(child_object_2.sha512_checksum).to eq initial_fixity_value.to_s
          expect(child_object_3.sha512_checksum).to eq initial_fixity_value.to_s
          checksum_batch_process.file = checksum_csv_upload
          checksum_batch_process.save
          updated_child_object = ChildObject.find(10_736_292)
          updated_child_object_two = ChildObject.find(67_890)
          updated_child_object_three = ChildObject.find(12)
          expect(updated_child_object.sha512_checksum).to eq "6fe314934e4623e61084b7f590ddee5cb259db13d45901c96ac74e14a7c771164feaa3a4cdb087c0f5c1eb39d671f1040eb8c092cfd1743d07f24c081d1fcd75"
          expect(updated_child_object_two.sha512_checksum).to eq "b04e233da2e3b76fcfe2928f73e58f61351fec489d112acba1616f4d809f83722d07fb6fe62bf21a6b1ebcc4097b64458b39ee1e35235e3604234c0b3d9840ca"
          expect(updated_child_object_three.sha512_checksum).to eq "8ac52a77a818780d29fe390f9b69cebe5a64c06559161e2e5ba7b6f425e7cbf785b50172f5795d1fcd5c63fc99c46774eb6c470f8ca453063bf98f4470ce81b0"
        end

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
        checksum_batch_process.file = checksum_csv_upload
        checksum_batch_process.save
      end

      with_versioning do
        it "can't update child objects checksum based on csv import" do
          child_object = ChildObject.find(10_736_292)
          expect(child_object.sha512_checksum).to eq initial_fixity_value.to_s
          expect(checksum_batch_process.batch_ingest_events.first.reason).to eq "Skipping row [2] with child oid: 10736292, user does not have permission to update."
          expect(checksum_batch_process.batch_ingest_events.last.reason).to eq "Child objects that were not updated: [[\"10736292\", \"67890\", \"12\"]]."
        end
      end
    end
  end
end
