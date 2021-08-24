# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BatchProcess, type: :model, prep_metadata_sources: true do
  subject(:batch_process) { described_class.new(batch_action: "reassociate child oids") }
  let(:user) { FactoryBot.create(:user, uid: "mk2525") }
  let(:admin_set) { FactoryBot.create(:admin_set) }
  let(:role) { FactoryBot.create(:role, name: editor) }
  let(:csv_upload) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "reassociation_example_small.csv")) }
  let(:child_object_nil_values) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "reassociation_example_child_object_counts.csv")) }
  let(:child_object_with_missing_columns) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "reassociation_example_child_object_missing_columns.csv")) }
  let(:parent_object) { FactoryBot.create(:parent_object, oid: "2002826", admin_set_id: admin_set.id) }
  let(:parent_object_old_one) { FactoryBot.create(:parent_object, oid: "2004548", admin_set_id: admin_set.id) }
  let(:parent_object_old_two) { FactoryBot.create(:parent_object, oid: "2004549", admin_set_id: admin_set.id) }

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
    login_as(:user)
  end

  describe "child object reassociation with nil values for caption, label, viewing hint" do
    before do
      user.add_role(:editor, admin_set)
      batch_process.user_id = user.id
      batch_process.file = child_object_nil_values
      batch_process.save
    end

    with_versioning do
      it "can set caption, label, viewing hint values to nil" do
        co = ChildObject.find(1_021_925)
        expect(co.caption).to be_nil
        expect(co.label).to be_nil
        expect(co.viewing_hint).to be_nil
      end
    end
  end

  describe "child object reassociation with missing column will not delete existing value" do
    before do
      user.add_role(:editor, admin_set)
      batch_process.user_id = user.id
    end

    with_versioning do
      it "does not delete already existing values if column is missing" do
        co = ChildObject.find(1_021_925)
        co.label = "TEST LABEL STAY SAME"
        co.caption = "TEST LABEL STAY SAME2"
        co.order = 3_445_234
        co.viewing_hint = nil
        co.parent_object.authoritative_json["title"] = "po_title"
        co.parent_object.call_number = "call_number"
        co.save
        batch_process.file = child_object_with_missing_columns
        batch_process.save
        co = ChildObject.find(1_021_925)
        expect(co.label).to eq "TEST LABEL STAY SAME"
        expect(co.caption).to eq "TEST LABEL STAY SAME2"
        expect(co.order).to eq 3_445_234
        expect(co.viewing_hint).to eq "facing-pages"
        expect(co.parent_object.authoritative_json["title"]).to eq "po_title"
        expect(co.parent_object.call_number).to eq "call_number"
      end
    end
  end

  describe "reassociation as a user with an editor role" do
    # Original oids [2002826, 2004548, 2004548, 2004549, 2004549]
    before do
      user.add_role(:editor, admin_set)
      batch_process.user_id = user.id
      batch_process.file = csv_upload
      batch_process.save
    end

    with_versioning do
      it "can update child and parent object relationships based on csv import" do
        co_one = ChildObject.find(1_011_398)
        co_three = ChildObject.find(1_021_926)
        po = ParentObject.find(2_002_826)
        po_old_one = ParentObject.find(2_004_548)
        po_old_two = ParentObject.find(2_004_549)
        expect(co_one.parent_object).to eq po
        expect(co_three.parent_object).to eq po
        expect(po.child_object_count).to eq 5
        expect(po_old_one.child_object_count).to eq 0
        expect(po_old_two.child_object_count).to eq 0
        expect(co_one.order).to eq 1
        expect(co_three.order).to eq 3
        expect(co_one.label).to eq "[Portrait of Grace Nail Johnson]"
        expect(co_three.label).to eq "Changed label, verso"
        expect(co_three).to have_a_version_with parent_object_oid: 2_004_548
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
      it "can't update child and parent object relationships based on csv import" do
        co_three = ChildObject.find(1_021_926)
        po = ParentObject.find(2_002_826)
        expect(co_three.parent_object).not_to eq po
      end
    end
  end

  # TODO: Move this set of tests to more appropriate location as feature matures
  it 'by default, PaperTrail will be turned off' do
    expect(PaperTrail).not_to be_enabled
  end

  with_versioning do
    it 'within a `with_versioning` block it will be turned on' do
      expect(PaperTrail).to be_enabled
    end
  end

  it 'can be turned on at the `it` or `describe` level', versioning: true do
    expect(PaperTrail).to be_enabled
  end
end
