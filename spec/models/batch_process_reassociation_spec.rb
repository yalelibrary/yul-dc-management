# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BatchProcess, type: :model, prep_metadata_sources: true do
  subject(:batch_process) { described_class.new(batch_action: 'reassociate child oids') }
  let(:user) { FactoryBot.create(:user, uid: 'mk2525') }
  let(:admin_set) { FactoryBot.create(:admin_set) }
  let(:role) { FactoryBot.create(:role, name: editor) }
  let(:csv_upload) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, 'csv', 'reassociation_example_small.csv')) }
  let(:child_object_nil_values) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, 'csv', 'reassociation_example_child_object_counts.csv')) }
  let(:child_object_caption_nil) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, 'csv', 'reassociation_example_child_caption.csv')) }
  let(:parent_object) { FactoryBot.create(:parent_object, oid: '2002826', admin_set_id: admin_set.id) }
  let(:parent_object_2) { FactoryBot.create(:parent_object, oid: '2004550', admin_set_id: admin_set.id) }
  let(:parent_object_old_one) do
    FactoryBot.create(:parent_object, oid: '2005512', admin_set_id: admin_set.id, authoritative_metadata_source_id: 3, aspace_uri: '/repositories/11/archival_objects/214638', child_object_count: 4)
  end
  let(:parent_object_old_two) do
    FactoryBot.create(:parent_object, oid: '2012036', admin_set_id: admin_set.id, authoritative_metadata_source_id: 3, aspace_uri: '/repositories/11/archival_objects/214639', child_object_count: 2)
  end
  let(:parent_object_old_three) { FactoryBot.create(:parent_object, oid: '2004551', admin_set_id: admin_set.id, bib: '34567', call_number: 'MSS MS 345') }
  let(:child_object_one) { FactoryBot.create(:child_object, oid: '1011398', parent_object: parent_object_old_one) }
  let(:child_object_two) { FactoryBot.create(:child_object, oid: '1021925', parent_object: parent_object_old_one) }
  let(:child_object_three) { FactoryBot.create(:child_object, oid: '1021926', parent_object: parent_object_old_one) }
  let(:child_object_four) { FactoryBot.create(:child_object, oid: '1021927', parent_object: parent_object_old_two) }
  let(:child_object_five) { FactoryBot.create(:child_object, oid: '1021928', parent_object: parent_object_old_two) }
  let(:child_object_1) { FactoryBot.create(:child_object, oid: '12345', parent_object: parent_object_old_three) }
  let(:child_object_2) { FactoryBot.create(:child_object, oid: '67890', parent_object: parent_object_old_three) }
  let(:child_object_3) { FactoryBot.create(:child_object, oid: '12', parent_object: parent_object_old_one) }
  let(:child_object_4) { FactoryBot.create(:child_object, oid: '123', parent_object: parent_object_old_one) }
  let(:child_object_5) { FactoryBot.create(:child_object, oid: '123456789', caption: 'caption', parent_object: parent_object_old_one) }

  around do |example|
    perform_enqueued_jobs do
      original_path_ocr = ENV['OCR_DOWNLOAD_BUCKET']
      ENV['OCR_DOWNLOAD_BUCKET'] = 'yul-dc-ocr-test'
      example.run
      ENV['OCR_DOWNLOAD_BUCKET'] = original_path_ocr
    end
  end

  before do
    stub_metadata_cloud('AS-2005512', 'aspace')
    stub_metadata_cloud('2002826')
    stub_metadata_cloud('AS-2012036', 'aspace')
    stub_ptiffs_and_manifests
    parent_object
    parent_object_2
    parent_object_old_one
    parent_object_old_two
    child_object_one
    child_object_two
    child_object_three
    child_object_four
    child_object_five
    child_object_1
    child_object_2
    child_object_3
    child_object_5
    login_as(:user)
  end

  describe 'child object reassociation with existing caption/label' do
    before do
      user.add_role(:editor, admin_set)
      batch_process.user_id = user.id
      batch_process.file = child_object_caption_nil
      batch_process.save
    end

    with_versioning do
      it 'will keep its caption/label value' do
        co = ChildObject.find('123456789')
        po = ParentObject.find('2004550')
        expect(co.parent_object).to eq po
        expect(co.caption).to eq 'caption'
      end
    end
  end

  describe 'child object reassociation with nil values for caption, label, viewing hint' do
    before do
      user.add_role(:editor, admin_set)
      batch_process.user_id = user.id
      batch_process.file = child_object_nil_values
      batch_process.save
    end

    with_versioning do
      it 'can set caption, label, viewing hint values to nil' do
        co = ChildObject.find(1_021_925)
        expect(co.caption).to be_nil
        expect(co.label).to be_nil
        expect(co.viewing_hint).to be_nil
      end
    end
  end

  describe 'reassociation as a user with an editor role' do
    # Original oids [2005512, 2005512, 2005512, 2012036, 2012036]
    before do
      user.add_role(:editor, admin_set)
      batch_process.user_id = user.id
      batch_process.file = csv_upload
      batch_process.save
    end

    with_versioning do
      it 'can update child and parent object relationships based on csv import' do
        co_one = ChildObject.find(1_011_398)
        co_three = ChildObject.find(1_021_926)
        po = ParentObject.find(2_002_826)
        po_old_one = ParentObject.find(2_005_512)
        po_old_two = ParentObject.find(2_012_036)
        expect(co_one.parent_object).to eq po
        expect(co_three.parent_object).to eq po
        expect(po.child_object_count).to eq 5
        # po_old_one had 2 child objects to start with
        expect(po_old_one.child_object_count).to eq 2
        # po_old_two loses all it's children so count is nil
        expect(po_old_two.child_object_count).to be_nil
        # and po_old_two becomes a redirected parent object
        expect(po_old_two.redirect_to).to eq "https://collections.library.yale.edu/catalog/#{po.oid}"
        expect(co_one.order).to eq 1
        expect(co_three.order).to eq 3
        expect(co_one.label).to eq '[Portrait of Grace Nail Johnson]'
        expect(co_three.label).to eq 'Changed label, verso'
        expect(co_three).to have_a_version_with parent_object_oid: 2_005_512
      end
    end
  end

  describe 'reassociation as a user without an editor role' do
    before do
      user.add_role(:viewer, admin_set)
      batch_process.user_id = user.id
      batch_process.file = csv_upload
      batch_process.save
    end

    with_versioning do
      it 'cannot update child and parent object relationships based on csv import' do
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
