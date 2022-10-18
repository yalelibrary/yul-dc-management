# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BatchProcess, type: :model, prep_metadata_sources: true do
  subject(:batch_process) { described_class.new(batch_action: "update child objects caption and label") }
  let(:user) { FactoryBot.create(:user, uid: "mk2525") }
  let(:admin_set) { FactoryBot.create(:admin_set) }
  let(:role) { FactoryBot.create(:role, name: editor) }
  let(:csv_upload) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "update_child_object_caption.csv")) }
  let(:parent_object) { FactoryBot.create(:parent_object, oid: "2002826", admin_set_id: admin_set.id) }
  let(:parent_object_2) { FactoryBot.create(:parent_object, oid: "2004548", admin_set_id: admin_set.id) }
  let(:child_object_2) { FactoryBot.create(:child_object, oid: "67890", caption: "co2 caption", label: "co2 label", parent_object: parent_object_2) }
  let(:child_object_3) { FactoryBot.create(:child_object, oid: "12", caption: "co3 caption", label: "co3 label", parent_object: parent_object_2) }
  let(:child_object) { FactoryBot.create(:child_object, caption: "caption", label: "label", parent_object: parent_object) }

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
    parent_object_2
    child_object
    child_object_2
    child_object_3
    login_as(:user)
  end

  describe "updating child object as a user with an editor role" do
    before do
      user.add_role(:editor, admin_set)
      batch_process.user_id = user.id
    end

    with_versioning do
      it "can update child and parent object relationships based on csv import" do
        expect(child_object.caption).to eq "caption"
        expect(child_object.label).to eq "label"
        expect(child_object_2.caption).to eq "co2 caption"
        expect(child_object_2.label).to eq "co2 label"
        expect(child_object_3.caption).to eq "co3 caption"
        expect(child_object_3.label).to eq "co3 label"
        batch_process.file = csv_upload
        batch_process.save
        updated_child_object = ChildObject.find(10736292)
        updated_child_object_2 = ChildObject.find(67890)
        updated_child_object_3 = ChildObject.find(12)
        expect(updated_child_object.caption).to eq "caption 2"
        expect(updated_child_object.label).to eq "label 2"
        expect(updated_child_object_2.caption).to eq "new caption"
        expect(updated_child_object_2.label).to eq "new label"
        expect(updated_child_object_3.caption).to eq "another caption"
        expect(updated_child_object_3.label).to eq "another label"
      end
    end
  end

  describe "reassociation as a user without an editor role" do
    before do
      user.add_role(:viewer, admin_set)
      batch_process.user_id = user.id
      batch_process.file = csv_upload
      batch_process.save
    end

    with_versioning do
      it "can't update child objects based on csv import" do
        child_object = ChildObject.find(10736292)
        expect(child_object.caption).to eq "caption"
        expect(child_object.label).to eq "label"
      end
    end
  end
end
