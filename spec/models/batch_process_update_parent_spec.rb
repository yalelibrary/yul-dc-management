# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BatchProcess, type: :model, prep_metadata_sources: true, prep_admin_sets: true do
  subject(:batch_process) { described_class.new }
  let(:user) { FactoryBot.create(:user, uid: 'mk2525') }
  let(:admin_set) { AdminSet.where(key: 'brbl').first }
  let(:create_owp_parent) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, 'csv', 'create_owp_parent.csv')) }
  let(:create_invalid_owp_parent) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, 'csv', 'create_invalid_owp_parent.csv')) }
  let(:permission_set) { FactoryBot.create(:permission_set, key: 'PS Key') }
  let(:csv_upload) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, 'csv', 'short_fixture_ids.csv')) }
  let(:csv_small) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, 'csv', 'update_example.csv')) }
  let(:csv_small_owp) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, 'csv', 'update_example_owp.csv')) }
  let(:invalid_ps) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, 'csv', 'update_example_invalid_ps.csv')) }
  let(:blank_ps) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, 'csv', 'update_example_blank_ps.csv')) }
  let(:invalid_user_csv) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, 'csv', 'update_example_invalid_user.csv')) }
  let(:csv_missing) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, 'csv', 'update_example_missing.csv')) }
  let(:csv_invalid) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, 'csv', 'update_example_invalid.csv')) }
  let(:csv_blanks) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, 'csv', 'update_example_blanks.csv')) }
  let(:csv_invalid_blanks) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, 'csv', 'update_example_invalid_blanks.csv')) }
  let(:csv_new_admin_set) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, 'csv', 'update_example_new_admin_set.csv')) }
  let(:pre_preservica_parent) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, 'csv', 'update_example_pre_preservica.csv')) }
  let(:csv_preservica) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, 'csv', 'update_example_preservica.csv')) }
  let(:csv_lowercase_preservica) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, 'csv', 'update_example_lowercase_preservica.csv')) }

  before do
    stub_metadata_cloud('2034600')
    stub_metadata_cloud('AS-2005512', 'aspace')
    stub_metadata_cloud('16414889')
    stub_metadata_cloud('14716192')
    stub_metadata_cloud('16854285')
    stub_preservica_aspace_single # oid: 200000000
    stub_preservica_login
    stub_ptiffs_and_manifests
    permission_set
    login_as(:user)
    batch_process.user_id = user.id
    fixtures = %w[preservica/api/entity/structural-objects/7fe35e8c-c21a-444a-a2e2-e3c926b519c5/children
                  preservica/api/entity/information-objects/1e42a2bb-8953-41b6-bcc3-1a19c86a5e3r/representations
                  preservica/api/entity/information-objects/1e42a2bb-8953-41b6-bcc3-1a19c86a5e3r/representations/Access
                  preservica/api/entity/information-objects/1e42a2bb-8953-41b6-bcc3-1a19c86a5e3r/representations/Preservation
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b486/generations
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b486/generations/1
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b486/generations/1/bitstreams/1
                  preservica/api/entity/information-objects/1e42a2bb-8953-41b6-bcc3-1a19c86a5e3d/representations
                  preservica/api/entity/information-objects/1e42a2bb-8953-41b6-bcc3-1a19c86a5e3d/representations/Access
                  preservica/api/entity/information-objects/1e42a2bb-8953-41b6-bcc3-1a19c86a5e3d/representations/Preservation
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b489/generations
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b489/generations/1
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b489/generations/1/bitstreams/1
                  preservica/api/entity/information-objects/f44ba97e-af2b-498e-b118-ed1247822f44/representations
                  preservica/api/entity/information-objects/f44ba97e-af2b-498e-b118-ed1247822f44/representations/Access
                  preservica/api/entity/information-objects/f44ba97e-af2b-498e-b118-ed1247822f44/representations/Preservation
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b487/generations
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b487/generations/1
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b487/generations/1/bitstreams/1]

    fixtures.each do |fixture|
      stub_request(:get, "https://test#{fixture}").to_return(
        status: 200, body: File.open(File.join(fixture_path, "#{fixture}.xml"))
      )
    end
    stub_preservica_tifs_set_of_three
  end

  around do |example|
    preservica_host = ENV['PRESERVICA_HOST']
    preservica_creds = ENV['PRESERVICA_CREDENTIALS']
    ENV['PRESERVICA_HOST'] = 'testpreservica'
    ENV['PRESERVICA_CREDENTIALS'] = '{"brbl": {"username":"xxxxx", "password":"xxxxx"}}'
    original_image_bucket = ENV['S3_SOURCE_BUCKET_NAME']
    original_path_ocr = ENV['OCR_DOWNLOAD_BUCKET']
    ENV['S3_SOURCE_BUCKET_NAME'] = 'yale-test-image-samples'
    ENV['OCR_DOWNLOAD_BUCKET'] = 'yul-dc-ocr-test'
    example.run
    ENV['S3_SOURCE_BUCKET_NAME'] = original_image_bucket
    ENV['OCR_DOWNLOAD_BUCKET'] = original_path_ocr
    ENV['PRESERVICA_HOST'] = preservica_host
    ENV['PRESERVICA_CREDENTIALS'] = preservica_creds
  end

  describe 'batch update parent' do
    it 'includes the originating user NETid' do
      batch_process.user_id = user.id
      expect(batch_process.user.uid).to eq 'mk2525'
    end
  end

  # TODO: refactor test to be more consistent, passes locally but occassionally fails in CI
  context 'updating a ParentObject from an import with all columns' do
    it 'can update a parent_object from a csv' do
      permission_set.add_administrator(user)
      expect do
        batch_process.file = csv_upload
        batch_process.save
        batch_process.create_new_parent_csv
      end.to change { ParentObject.count }.from(0).to(5).or change { ParentObject.count }.from(0).to(3)
      po_original = ParentObject.find_by(oid: 2_034_600)
      expect(po_original.aspace_uri).to be_nil
      expect(po_original.barcode).to be_nil
      expect(po_original.bib).to be_nil
      expect(po_original.digital_object_source).to eq 'None'
      expect(po_original.digitization_note).to be_nil
      expect(po_original.display_layout).to be_nil
      expect(po_original.extent_of_digitization).to be_nil
      expect(po_original.holding).to be_nil
      expect(po_original.item).to be_nil
      expect(po_original.preservica_representation_type).to be_nil
      expect(po_original.preservica_uri).to be_nil
      expect(po_original.rights_statement).to be_nil
      expect(po_original.viewing_direction).to be_nil
      expect(po_original.visibility).to eq 'Private'

      pos = ParentObject.all
      pos[0].admin_set = admin_set
      pos[1].admin_set = admin_set
      pos[2].admin_set = admin_set
      pos[3].admin_set = admin_set if ParentObject.all.count > 3
      pos[4].admin_set = admin_set if ParentObject.all.count > 4
      update_batch_process = described_class.new(batch_action: 'update parent objects', user_id: user.id)
      expect do
        update_batch_process.file = csv_small_owp
        update_batch_process.save
        update_batch_process.update_parent_objects
      end.not_to change { ParentObject.count }
      po_updated = ParentObject.find_by(oid: 2_034_600)

      expect(po_updated.aspace_uri).to eq '/repositories/11/archival_objects/515305'
      expect(po_updated.barcode).to eq '39002102340669'
      expect(po_updated.bib).to eq '12307100'
      expect(po_updated.digital_object_source).to eq 'None'
      expect(po_updated.digitization_note).to eq '5678'
      expect(po_updated.display_layout).to eq 'paged'
      expect(po_updated.extent_of_digitization).to eq 'Completely digitized'
      expect(po_updated.holding).to eq 'temporary'
      expect(po_updated.item).to eq 'reel'
      expect(po_original.preservica_representation_type).to be_nil
      expect(po_original.preservica_uri).to be_nil
      expect(po_updated.rights_statement).to eq 'The use of this image may be subject to the copyright law of the United States'
      expect(po_updated.viewing_direction).to eq 'left-to-right'
      expect(po_updated.visibility).to eq 'Open with Permission'
      expect(po_updated.permission_set_id).to eq permission_set.id
      expect(po_updated.sensitive_materials).to eq 'Yes'
    end

    it 'does not update successfully if permission set is invalid' do
      permission_set.add_administrator(user)
      expect do
        batch_process.file = csv_upload
        batch_process.save
        batch_process.create_new_parent_csv
      end.to change { ParentObject.count }.from(0).to(5).or change { ParentObject.count }.from(0).to(3)
      po_original = ParentObject.find_by(oid: 2_034_600)
      expect(po_original.aspace_uri).to be_nil
      expect(po_original.barcode).to be_nil
      expect(po_original.bib).to be_nil
      expect(po_original.digital_object_source).to eq 'None'
      expect(po_original.digitization_note).to be_nil
      expect(po_original.display_layout).to be_nil
      expect(po_original.extent_of_digitization).to be_nil
      expect(po_original.holding).to be_nil
      expect(po_original.item).to be_nil
      expect(po_original.preservica_representation_type).to be_nil
      expect(po_original.preservica_uri).to be_nil
      expect(po_original.rights_statement).to be_nil
      expect(po_original.viewing_direction).to be_nil
      expect(po_original.visibility).to eq 'Private'

      pos = ParentObject.all
      pos[0].admin_set = admin_set
      pos[1].admin_set = admin_set
      pos[2].admin_set = admin_set
      pos[3].admin_set = admin_set if ParentObject.all.count > 3
      pos[4].admin_set = admin_set if ParentObject.all.count > 4
      update_batch_process = described_class.new(batch_action: 'update parent objects', user_id: user.id)
      expect do
        update_batch_process.file = invalid_ps
        update_batch_process.save
        update_batch_process.update_parent_objects
      end.not_to change { ParentObject.count }
      po_updated = ParentObject.find_by(oid: 2_034_600)

      expect(po_updated.aspace_uri).to be_nil
      expect(po_updated.barcode).to be_nil
      expect(po_updated.bib).to be_nil
      expect(po_updated.digital_object_source).to eq 'None'
      expect(po_updated.digitization_note).to be_nil
      expect(po_updated.display_layout).to be_nil
      expect(po_updated.extent_of_digitization).to be_nil
      expect(po_updated.holding).to be_nil
      expect(po_updated.item).to be_nil
      expect(po_updated.preservica_representation_type).to be_nil
      expect(po_updated.preservica_uri).to be_nil
      expect(po_updated.rights_statement).to be_nil
      expect(po_updated.viewing_direction).to be_nil
      expect(po_updated.visibility).to eq "Private"
      expect(update_batch_process.batch_ingest_events.first.reason).to eq 'Skipping row [2]. Process failed. Permission Set missing or nonexistent.'
      expect(update_batch_process.batch_ingest_events_count).to eq 1
    end

    it 'does not update successfully if permission set is blank' do
      permission_set.add_administrator(user)
      expect do
        batch_process.file = csv_upload
        batch_process.save
        batch_process.create_new_parent_csv
      end.to change { ParentObject.count }.from(0).to(5).or change { ParentObject.count }.from(0).to(3)
      po_original = ParentObject.find_by(oid: 2_034_600)
      expect(po_original.aspace_uri).to be_nil
      expect(po_original.barcode).to be_nil
      expect(po_original.bib).to be_nil
      expect(po_original.digital_object_source).to eq 'None'
      expect(po_original.digitization_note).to be_nil
      expect(po_original.display_layout).to be_nil
      expect(po_original.extent_of_digitization).to be_nil
      expect(po_original.holding).to be_nil
      expect(po_original.item).to be_nil
      expect(po_original.preservica_representation_type).to be_nil
      expect(po_original.preservica_uri).to be_nil
      expect(po_original.rights_statement).to be_nil
      expect(po_original.viewing_direction).to be_nil
      expect(po_original.visibility).to eq 'Private'

      pos = ParentObject.all
      pos[0].admin_set = admin_set
      pos[1].admin_set = admin_set
      pos[2].admin_set = admin_set
      pos[3].admin_set = admin_set if ParentObject.all.count > 3
      pos[4].admin_set = admin_set if ParentObject.all.count > 4
      update_batch_process = described_class.new(batch_action: 'update parent objects', user_id: user.id)
      expect do
        update_batch_process.file = blank_ps
        update_batch_process.save
        update_batch_process.update_parent_objects
      end.not_to change { ParentObject.count }
      po_updated = ParentObject.find_by(oid: 2_034_600)

      expect(po_updated.aspace_uri).to be_nil
      expect(po_updated.barcode).to be_nil
      expect(po_updated.bib).to be_nil
      expect(po_updated.digital_object_source).to eq 'None'
      expect(po_updated.digitization_note).to be_nil
      expect(po_updated.display_layout).to be_nil
      expect(po_updated.extent_of_digitization).to be_nil
      expect(po_updated.holding).to be_nil
      expect(po_updated.item).to be_nil
      expect(po_updated.preservica_representation_type).to be_nil
      expect(po_updated.preservica_uri).to be_nil
      expect(po_updated.rights_statement).to be_nil
      expect(po_updated.viewing_direction).to be_nil
      expect(po_updated.visibility).to eq 'Private'
      expect(update_batch_process.batch_ingest_events.first.reason).to eq 'Skipping row [2]. Process failed. Permission Set missing from CSV.'
      expect(update_batch_process.batch_ingest_events_count).to eq 1
    end

    it 'does not update successfully if user does not have admin permission to permission set' do
      expect do
        batch_process.file = csv_upload
        batch_process.save
        batch_process.create_new_parent_csv
      end.to change { ParentObject.count }.from(0).to(5).or change { ParentObject.count }.from(0).to(3)
      po_original = ParentObject.find_by(oid: 2_034_600)
      expect(po_original.aspace_uri).to be_nil
      expect(po_original.barcode).to be_nil
      expect(po_original.bib).to be_nil
      expect(po_original.digital_object_source).to eq 'None'
      expect(po_original.digitization_note).to be_nil
      expect(po_original.display_layout).to be_nil
      expect(po_original.extent_of_digitization).to be_nil
      expect(po_original.holding).to be_nil
      expect(po_original.item).to be_nil
      expect(po_original.preservica_representation_type).to be_nil
      expect(po_original.preservica_uri).to be_nil
      expect(po_original.rights_statement).to be_nil
      expect(po_original.viewing_direction).to be_nil
      expect(po_original.visibility).to eq 'Private'

      pos = ParentObject.all
      pos[0].admin_set = admin_set
      pos[1].admin_set = admin_set
      pos[2].admin_set = admin_set
      pos[3].admin_set = admin_set if ParentObject.all.count > 3
      pos[4].admin_set = admin_set if ParentObject.all.count > 4
      update_batch_process = described_class.new(batch_action: 'update parent objects', user_id: user.id)
      expect do
        update_batch_process.file = invalid_user_csv
        update_batch_process.save
        update_batch_process.update_parent_objects
      end.not_to change { ParentObject.count }
      po_updated = ParentObject.find_by(oid: 2_034_600)

      expect(po_updated.aspace_uri).to be_nil
      expect(po_updated.barcode).to be_nil
      expect(po_updated.bib).to be_nil
      expect(po_updated.digital_object_source).to eq 'None'
      expect(po_updated.digitization_note).to be_nil
      expect(po_updated.display_layout).to be_nil
      expect(po_updated.extent_of_digitization).to be_nil
      expect(po_updated.holding).to be_nil
      expect(po_updated.item).to be_nil
      expect(po_updated.preservica_representation_type).to be_nil
      expect(po_updated.preservica_uri).to be_nil
      expect(po_updated.rights_statement).to be_nil
      expect(po_updated.viewing_direction).to be_nil
      expect(po_updated.visibility).to eq 'Private'
      expect(update_batch_process.batch_ingest_events_count).to eq 1
      expect(update_batch_process.batch_ingest_events.first.reason).to eq 'Skipping row [2] because user does not have edit permissions for this Permission Set: PS Key'
    end
  end

  context 'updating a ParentObject from an import with some columns' do
    it 'can update a parent_object from a csv' do
      expect do
        batch_process.file = csv_upload
        batch_process.save
        batch_process.create_new_parent_csv
      end.to change { ParentObject.count }.from(0).to(5).or change { ParentObject.count }.from(0).to(3)
      po_original = ParentObject.find_by(oid: 2_034_600)

      expect(po_original.aspace_uri).to be_nil
      expect(po_original.barcode).to be_nil
      expect(po_original.bib).to be_nil
      expect(po_original.digitization_note).to be_nil
      expect(po_original.display_layout).to be_nil
      expect(po_original.extent_of_digitization).to be_nil
      expect(po_original.holding).to be_nil
      expect(po_original.item).to be_nil
      expect(po_original.rights_statement).to be_nil
      expect(po_original.viewing_direction).to be_nil
      expect(po_original.visibility).to eq 'Private'
      pos = ParentObject.all
      pos[0].admin_set = admin_set
      pos[1].admin_set = admin_set
      pos[2].admin_set = admin_set
      pos[3].admin_set = admin_set if ParentObject.all.count > 3
      pos[4].admin_set = admin_set if ParentObject.all.count > 4

      update_batch_process = described_class.new(batch_action: 'update parent objects', user_id: user.id)
      expect do
        update_batch_process.file = csv_missing
        update_batch_process.save
        update_batch_process.update_parent_objects
      end.not_to change { ParentObject.count }
      po_updated = ParentObject.find_by(oid: 2_034_600)

      expect(po_updated.aspace_uri).to be_nil
      expect(po_updated.barcode).to be_nil
      expect(po_updated.bib).to be_nil
      expect(po_updated.digitization_note).to be_nil
      expect(po_updated.display_layout).to eq 'paged'
      expect(po_updated.extent_of_digitization).to be_nil
      expect(po_updated.holding).to be_nil
      expect(po_updated.item).to be_nil
      expect(po_updated.rights_statement).to be_nil
      expect(po_updated.viewing_direction).to be_nil
      expect(po_updated.visibility).to eq 'Yale Community Only'
    end
    it 'can update a parent objects admin set' do
      expect do
        batch_process.file = csv_upload
        batch_process.save
        batch_process.create_new_parent_csv
      end.to change { ParentObject.count }.from(0).to(5).or change { ParentObject.count }.from(0).to(3)
      po_original = ParentObject.find_by(oid: 2_034_600)
      expect(po_original.visibility).to eq 'Private'
      expect(po_original.admin_set.key).to eq 'brbl'
      update_batch_process = described_class.new(batch_action: 'update parent objects', user_id: user.id)
      expect do
        update_batch_process.file = csv_new_admin_set
        update_batch_process.save
        update_batch_process.update_parent_objects
      end.not_to change { ParentObject.count }
      po_updated = ParentObject.find_by(oid: 2_034_600)
      expect(po_updated.visibility).to eq 'Public'
      expect(po_updated.admin_set.key).to eq 'sml'
    end
  end

  context 'updating a ParentObject from an import with invalid fields' do
    it 'will not update a parent_object from a csv' do
      expect do
        batch_process.file = csv_upload
        batch_process.save
        batch_process.create_new_parent_csv
      end.to change { ParentObject.count }.from(0).to(5).or change { ParentObject.count }.from(0).to(3)
      po_original = ParentObject.find_by(oid: 2_034_600)

      expect(po_original.aspace_uri).to be_nil
      expect(po_original.barcode).to be_nil
      expect(po_original.bib).to be_nil
      expect(po_original.digitization_note).to be_nil
      expect(po_original.display_layout).to be_nil
      expect(po_original.extent_of_digitization).to be_nil
      expect(po_original.holding).to be_nil
      expect(po_original.item).to be_nil
      expect(po_original.rights_statement).to be_nil
      expect(po_original.viewing_direction).to be_nil
      expect(po_original.visibility).to eq 'Private'
      pos = ParentObject.all
      pos[0].admin_set = admin_set
      pos[1].admin_set = admin_set
      pos[2].admin_set = admin_set
      pos[3].admin_set = admin_set if ParentObject.all.count > 3
      pos[4].admin_set = admin_set if ParentObject.all.count > 4

      update_batch_process = described_class.new(batch_action: 'update parent objects', user_id: user.id)
      expect do
        update_batch_process.file = csv_invalid
        update_batch_process.save
        update_batch_process.update_parent_objects
      end.not_to change { ParentObject.count }
      po_updated = ParentObject.find_by(oid: 2_034_600)

      expect(po_updated.aspace_uri).to be_nil
      expect(po_updated.barcode).to be_nil
      expect(po_updated.bib).to be_nil
      expect(po_updated.digitization_note).to be_nil
      expect(po_updated.display_layout).to be_nil
      expect(po_updated.extent_of_digitization).to be_nil
      expect(po_updated.holding).to be_nil
      expect(po_updated.item).to be_nil
      expect(po_updated.rights_statement).to be_nil
      expect(po_updated.viewing_direction).to be_nil
      expect(po_updated.visibility).to eq 'Private'
    end
  end

  context 'updating to blank a ParentObject with valid fields' do
    before do # setup po with some valid values
      batch_process.file = csv_upload
      batch_process.save
      batch_process.create_new_parent_csv
      pos = ParentObject.all
      pos[0].admin_set = admin_set
      pos[1].admin_set = admin_set
      pos[2].admin_set = admin_set
      pos[3].admin_set = admin_set if ParentObject.all.count > 3
      pos[4].admin_set = admin_set if ParentObject.all.count > 4
      update_batch_process = described_class.new(batch_action: 'update parent objects', user_id: user.id)
      update_batch_process.file = csv_small
      update_batch_process.save
      update_batch_process.update_parent_objects
      po_updated = ParentObject.find_by(oid: 2_034_600)
      expect(po_updated.aspace_uri).to eq '/repositories/11/archival_objects/515305'
      expect(po_updated.barcode).to eq '39002102340669'
      expect(po_updated.bib).to eq '12307100'
      expect(po_updated.digitization_note).to eq '5678'
      expect(po_updated.display_layout).to eq 'paged'
      expect(po_updated.extent_of_digitization).to eq 'Completely digitized'
      expect(po_updated.holding).to eq 'temporary'
      expect(po_updated.item).to eq 'reel'
      expect(po_updated.project_identifier).to eq 'Beinecke'
      expect(po_updated.rights_statement).to eq 'The use of this image may be subject to the copyright law of the United States'
      expect(po_updated.viewing_direction).to eq 'left-to-right'
      expect(po_updated.visibility).to eq 'Public'
    end

    it 'can blank out some values' do
      update_batch_process = described_class.new(batch_action: 'update parent objects', user_id: user.id)
      update_batch_process.file = csv_blanks
      update_batch_process.save
      update_batch_process.update_parent_objects
      po_updated = ParentObject.find_by(oid: 2_034_600)
      expect(po_updated.aspace_uri).to eq '/repositories/11/archival_objects/515305'
      expect(po_updated.barcode).to eq '39002102340669'
      expect(po_updated.bib).to eq '12307100'
      expect(po_updated.digitization_note).to eq '5678'
      expect(po_updated.display_layout).to be_nil
      expect(po_updated.project_identifier).to be_nil
      expect(po_updated.extent_of_digitization).to eq 'Completely digitized'
      expect(po_updated.holding).to eq 'temporary'
      expect(po_updated.item).to eq 'reel'
      expect(po_updated.rights_statement).to eq 'The use of this image may be subject to the copyright law of the United States'
      expect(po_updated.viewing_direction).to be_nil
      expect(po_updated.visibility).to eq 'Public'
    end

    it 'can not blank out some values' do
      update_batch_process = described_class.new(batch_action: 'update parent objects', user_id: user.id)
      update_batch_process.file = csv_invalid_blanks
      update_batch_process.save
      update_batch_process.update_parent_objects

      po_updated = ParentObject.find_by(oid: 2_034_600)
      expect(po_updated.aspace_uri).to eq '/repositories/11/archival_objects/515305'
      expect(po_updated.barcode).to eq '39002102340669'
      expect(po_updated.bib).to eq '12307100'
      expect(po_updated.digitization_note).to eq '5678'
      expect(po_updated.display_layout).to be_nil
      expect(po_updated.project_identifier).to be_nil
      expect(po_updated.extent_of_digitization).to eq 'Completely digitized'
      expect(po_updated.holding).to eq 'temporary'
      expect(po_updated.item).to eq 'reel'
      expect(po_updated.rights_statement).to eq 'The use of this image may be subject to the copyright law of the United States'
      expect(po_updated.viewing_direction).to be_nil
      expect(po_updated.visibility).to eq 'Public'
      expect(update_batch_process.batch_ingest_events_count).to eq 2
      expect(update_batch_process.batch_ingest_events.first.reason).to eq 'Parent 2034600 did not update value for source because it can not be blanked.'
      expect(update_batch_process.batch_ingest_events.second.reason).to eq 'Parent 2034600 did not update value for visibility because it can not be blanked.'
    end
  end

  context 'updating a ParentObject from an import with valid preservica fields' do
    it 'can update preservica fields and get new children from preservica' do
      expect do
        batch_process.file = pre_preservica_parent
        batch_process.save
        batch_process.create_new_parent_csv
      end.to change { ParentObject.count }.from(0).to(1)
      po_original = ParentObject.find_by(oid: 200_000_000)
      expect(po_original.digital_object_source).to eq 'None'
      expect(po_original.preservica_representation_type).to be_nil
      expect(po_original.preservica_uri).to be_nil
      expect(po_original.child_objects.count).to eq 0

      update_batch_process = described_class.new(batch_action: 'update parent objects', user_id: user.id)
      update_batch_process.file = csv_preservica
      update_batch_process.save
      update_batch_process.update_parent_objects
      po_updated = ParentObject.find_by(oid: 200_000_000)
      expect(po_updated.digital_object_source).to eq 'Preservica'
      expect(po_updated.preservica_representation_type).to eq 'Preservation'
      expect(po_updated.preservica_uri).to eq '/preservica/api/entity/structural-objects/7fe35e8c-c21a-444a-a2e2-e3c926b519c5'
      expect(po_updated.child_objects.count).to eq 3
    end

    it 'can update preservica fields and get new children from preservica with a lowercase preservica and preservation' do
      expect do
        batch_process.file = pre_preservica_parent
        batch_process.save
        batch_process.create_new_parent_csv
      end.to change { ParentObject.count }.from(0).to(1)
      po_original = ParentObject.find_by(oid: 200_000_000)
      expect(po_original.digital_object_source).to eq 'None'
      expect(po_original.preservica_representation_type).to be_nil
      expect(po_original.preservica_uri).to be_nil
      expect(po_original.child_objects.count).to eq 0

      update_batch_process = described_class.new(batch_action: 'update parent objects', user_id: user.id)
      update_batch_process.file = csv_lowercase_preservica
      update_batch_process.save
      update_batch_process.update_parent_objects
      po_updated = ParentObject.find_by(oid: 200_000_000)
      expect(po_updated.digital_object_source).to eq 'preservica'
      expect(po_updated.preservica_representation_type).to eq 'preservation'
      expect(po_updated.preservica_uri).to eq '/preservica/api/entity/structural-objects/7fe35e8c-c21a-444a-a2e2-e3c926b519c5'
      expect(po_updated.child_objects.count).to eq 3
    end
  end
end
