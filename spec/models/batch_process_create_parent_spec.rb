# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BatchProcess, type: :model, prep_metadata_sources: true, prep_admin_sets: true do
  subject(:batch_process) { described_class.new }
  let(:user) { FactoryBot.create(:user, uid: 'mk2525') }
  let(:admin_set_one) { FactoryBot.create(:admin_set, key: 'jss') }
  let(:create_owp_parent) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "create_owp_parent.csv")) }
  let(:create_invalid_owp_parent) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "create_invalid_owp_parent.csv")) }
  let(:create_invalid_sensitive_materials_parent) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "create_invalid_sensitive_materials_parent.csv")) }
  let(:mini_create_owp_parent) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "mini_owp_parent.csv")) }
  let(:permission_set) { FactoryBot.create(:permission_set, key: "PS Key") }
  let(:no_oid_parent) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, 'csv', 'parent_no_oid.csv')) }
  let(:no_admin_set) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, 'csv', 'parent_no_admin_set.csv')) }
  let(:no_source) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, 'csv', 'parent_no_source.csv')) }
  let(:no_extent) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, 'csv', 'aspace_parent_no_extent.csv')) }
  let(:typo_extent) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, 'csv', 'aspace_parent_typo_extent.csv')) }
  let(:aspace_parent) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, 'csv', 'aspace_parent.csv')) }
  let(:alma_parent) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, 'csv', 'create_alma_parent.csv')) }

  around do |example|
    original_image_bucket = ENV['S3_SOURCE_BUCKET_NAME']
    original_access_primary_mount = ENV['ACCESS_PRIMARY_MOUNT']
    ENV['S3_SOURCE_BUCKET_NAME'] = 'yale-test-image-samples'
    ENV['ACCESS_PRIMARY_MOUNT'] = File.join('spec', 'fixtures', 'images', 'access_primaries')
    perform_enqueued_jobs do
      example.run
    end
    ENV['S3_SOURCE_BUCKET_NAME'] = original_image_bucket
    ENV['ACCESS_PRIMARY_MOUNT'] = original_access_primary_mount
  end

  before do
    user.add_role(:editor, admin_set_one)
    login_as(:user)
    batch_process.user_id = user.id
    permission_set
  end

  describe 'with the metadata cloud mocked' do
    before do
      stub_metadata_cloud('AS-781086', 'aspace')
      stub_metadata_cloud('200000045')
      stub_metadata_cloud('2002826')
      stub_metadata_cloud('A-15821166', 'alma')
    end

    context 'Create Parent Object batch process with a detailed csv' do
      it 'can create a parent object from aspace' do
        expect do
          batch_process.file = aspace_parent
          batch_process.save
        end.to change { ParentObject.count }.from(0).to(1)
        po = ParentObject.first
        expect(po.bib).to eq('4320085')
        expect(po.aspace_uri).to eq('/repositories/12/archival_objects/781086')
        expect(po.sensitive_materials).to eq('Yes')
      end
      it 'can create a parent object from alma' do
        expect do
          batch_process.file = alma_parent
          batch_process.save
        end.to change { ParentObject.count }.from(0).to(1)
        po = ParentObject.first
        expect(po.mms_id).to eq('9981952153408651')
        expect(po.alma_item).to eq('23233086230008651')
        expect(po.alma_holding).to eq('22233086240008651')
        expect(po.last_alma_update).not_to be_nil
      end
      it 'can create a parent_object' do
        expect do
          batch_process.file = no_oid_parent
          batch_process.save
        end.to change { ParentObject.count }.from(0).to(1)
        po = ParentObject.first
        expect(po.oid).not_to be_nil
      end
      it 'fails creating a parent_object with invalid Sensitive Materials value' do
        permission_set.add_administrator(user)
        expect do
          batch_process.file = create_invalid_sensitive_materials_parent
          batch_process.save
        end.not_to change { ParentObject.count }
        expect(batch_process.batch_ingest_events[0].reason).to eq("Skipping row [2] Unable to save parent: Validation failed: Sensitive materials must be 'Yes' or 'No'.")
      end
      it 'can create an OwP parent_object' do
        permission_set.add_administrator(user)
        expect do
          batch_process.file = create_owp_parent
          batch_process.save
        end.to change { ParentObject.count }.from(0).to(1)
        po = ParentObject.first
        expect(po.visibility).to eq('Open with Permission')
        expect(po.permission_set).to eq(permission_set)
      end
      it 'fails creating an OwP parent_object with invalid Permission Set key' do
        permission_set.add_administrator(user)
        expect do
          batch_process.file = create_invalid_owp_parent
          batch_process.save
        end.not_to change { ParentObject.count }
        expect(batch_process.batch_ingest_events[0].reason).to eq('Skipping row [2]. Process failed. Permission Set missing or nonexistent.')
      end
      it 'fails creating an OwP parent_object if user does not have admin privelages' do
        expect do
          batch_process.file = create_owp_parent
          batch_process.save
        end.not_to change { ParentObject.count }
        expect(batch_process.batch_ingest_events[0].reason).to eq('Skipping row [2] because user does not have edit permissions for this Permission Set: PS Key')
      end
      # rubocop:disable Layout/LineLength
      it 'can fail when csv has no admin set' do
        expect do
          batch_process.file = no_admin_set
          batch_process.save
        end.not_to change { ParentObject.count }
        expect(batch_process.batch_ingest_events[0].reason).to eq('The admin set code is missing or incorrect. Please ensure an admin_set value is in the correct spreadsheet column and that your 3 or 4 letter code is correct. ------------ Message from System: Skipping row [2] with unknown admin set [] for parent: ')
      end
      # rubocop:enable Layout/LineLength
      it 'can fail when csv has no source' do
        expect do
          batch_process.file = no_source
          batch_process.save
        end.not_to change { ParentObject.count }
        expect(batch_process.batch_ingest_events[0].reason).to eq('Skipping row [2]. Source cannot be blank.')
      end
      it 'can fail when aspace is source but no extent of digitization is provided' do
        expect do
          batch_process.file = no_extent
          batch_process.save
        end.not_to change { ParentObject.count }
        expect(batch_process.batch_ingest_events[0].reason).to eq('Skipping row [2] with parent oid: 200000000.  Parent objects with ASpace as a source must have an Extent of Digitization value.')
      end
      it 'can fail when aspace is source but extent of digitization is not an accepted value' do
        expect do
          batch_process.file = typo_extent
          batch_process.save
        end.not_to change { ParentObject.count }
        expect(batch_process.batch_ingest_events[0].reason).to eq("Skipping row [2] with parent oid: 200000000.  Extent of Digitization value must be 'Completely digitized' or 'Partially digitized'.")
      end
      context 'with minimal csv data and OwP itemPermission' do
        it 'fails when no Permission Set key is submitted' do
          expect do
            batch_process.file = mini_create_owp_parent
            batch_process.save
          end.to change { ParentObject.count }.from(0).to(1)
          po = ParentObject.first
          expect(po.visibility).to eq "Private"
          expect(po.events_for_batch_process(batch_process)[1].reason).to include("SetupMetadataJob failed. Permission Set information missing or nonexistent from CSV.")
        end
      end
    end
  end
end
