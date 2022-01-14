# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BatchProcess, type: :model, prep_metadata_sources: true do
  subject(:batch_process) { described_class.new(batch_action: "reassociate child oids") }
  let(:user) { FactoryBot.create(:user, uid: "mk2525") }
  let(:admin_set) { FactoryBot.create(:admin_set) }
  let(:role) { FactoryBot.create(:role, name: editor) }
  let(:csv_upload) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "reassociation_example_small.csv")) }
  let(:redirect) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "reassociation_example_redirect.csv")) }
  let(:do_not_redirect) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "reassociation_example_do_not_redirect.csv")) }
  let(:parent_object) { FactoryBot.create(:parent_object, oid: "2002826", admin_set_id: admin_set.id) }
  let(:parent_object_2) { FactoryBot.create(:parent_object, oid: "2004550", admin_set_id: admin_set.id) }
  let(:parent_object_old_one) { FactoryBot.create(:parent_object, oid: "2004548", admin_set_id: admin_set.id) }
  let(:parent_object_old_two) { FactoryBot.create(:parent_object, oid: "2004549", admin_set_id: admin_set.id) }
  let(:parent_object_old_three) { FactoryBot.create(:parent_object, oid: "2004551", admin_set_id: admin_set.id, bib: "34567", call_number: "MSS MS 345") }
  let(:child_object_1) { FactoryBot.create(:child_object, oid: "12345", parent_object: parent_object_old_three) }
  let(:child_object_2) { FactoryBot.create(:child_object, oid: "67890", parent_object: parent_object_old_three) }
  let(:child_object_3) { FactoryBot.create(:child_object, oid: "12", parent_object: parent_object_old_one) }
  let(:child_object_4) { FactoryBot.create(:child_object, oid: "123", parent_object: parent_object_old_one) }

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
    stub_metadata_cloud("2004549")
    stub_ptiffs_and_manifests
    parent_object
    parent_object_old_one
    parent_object_old_two
    child_object_1
    child_object_2
    child_object_3
    login_as(:user)
  end

  describe "redirect objects that lose all children during reassociation batch process" do
    # Original oid 2004551
    before do
      parent_object_old_three
      parent_object_2
      user.add_role(:editor, admin_set)
      batch_process.user_id = user.id
      batch_process.file = redirect
      batch_process.save
    end

    it "can add redirect_to to parent objects that have all its children reassociated" do
      co = ChildObject.find(child_object_1.oid)
      # performed the reassociation
      expect(co.parent_object).to eq parent_object_2

      po_old_three = ParentObject.find(parent_object_old_three.oid)
      # created redirect
      expect(po_old_three.redirect_to).to eq("https://collections.library.yale.edu/catalog/2004550")
      expect(po_old_three.visibility).to eq("Redirect")
      expect(po_old_three.bib).to be_nil
      expect(po_old_three.call_number).to be_nil

      # still has child object
      po_old_one = ParentObject.find(parent_object_old_one.oid)
      expect(po_old_one.redirect_to).to be_nil
    end
  end

  describe "redirect objects that lose all children during reassociation batch process to different sources" do
    # Original oid 2004551
    before do
      parent_object_old_three
      parent_object_2
      user.add_role(:editor, admin_set)
      batch_process.user_id = user.id
      batch_process.file = do_not_redirect
      batch_process.save
    end

    it "does not create redirect_to from parent objects that have all its children reassociated" do
      co = ChildObject.find(child_object_1.oid)
      # performed the reassociation
      expect(co.parent_object).to eq parent_object_2

      po_old_three = ParentObject.find(parent_object_old_three.oid)
      # did not create redirect
      expect(po_old_three.redirect_to).to be_nil
      expect(po_old_three.visibility).to eq("Private")
      expect(po_old_three.bib).to eq("34567")
      expect(po_old_three.call_number).to eq("MSS MS 345")

      # still has child object
      po_old_one = ParentObject.find(parent_object_old_one.oid)
      expect(po_old_one.redirect_to).to be_nil
    end
  end
end
