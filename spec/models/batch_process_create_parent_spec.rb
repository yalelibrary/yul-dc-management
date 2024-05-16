# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BatchProcess, type: :model, prep_metadata_sources: true, prep_admin_sets: true do
  subject(:batch_process) { described_class.new }
  let(:user) { FactoryBot.create(:user, uid: 'mk2525') }
  let(:admin_set_one) { FactoryBot.create(:admin_set, key: 'jss') }
  let(:create_owp_parent) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "create_owp_parent.csv")) }
  let(:mini_create_owp_parent) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "owp_fixture_id.csv")) }
  let(:create_invalid_owp_parent) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "create_invalid_owp_parent.csv")) }
  let(:permission_set) { FactoryBot.create(:permission_set, key: "psKey") }
  let(:no_oid_parent) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, 'csv', 'parent_no_oid.csv')) }
  let(:no_admin_set) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, 'csv', 'parent_no_admin_set.csv')) }
  let(:no_source) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, 'csv', 'parent_no_source.csv')) }
  let(:no_extent) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, 'csv', 'aspace_parent_no_extent.csv')) }
  let(:typo_extent) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, 'csv', 'aspace_parent_typo_extent.csv')) }
  let(:aspace_parent) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, 'csv', 'aspace_parent.csv')) }

  around do |example|
    original_image_bucket = ENV['S3_SOURCE_BUCKET_NAME']
    original_access_master_mount = ENV['ACCESS_MASTER_MOUNT']
    ENV['S3_SOURCE_BUCKET_NAME'] = 'yale-test-image-samples'
    ENV['ACCESS_MASTER_MOUNT'] = File.join('spec', 'fixtures', 'images', 'access_masters')
    perform_enqueued_jobs do
      example.run
    end
    ENV['S3_SOURCE_BUCKET_NAME'] = original_image_bucket
    ENV['ACCESS_MASTER_MOUNT'] = original_access_master_mount
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
      stub_metadata_cloud('AS-2019479', 'aspace')
      stub_metadata_cloud('200000045', 'ladybird')
      stub_metadata_cloud('2002826', 'ladybird')
    end

    context 'Create Parent Object batch process with a csv' do
      it 'can create a parent object from aspace' do
        expect do
          batch_process.file = aspace_parent
          batch_process.save
        end.to change { ParentObject.count }.from(0).to(1)
        po = ParentObject.first
        # TODO: determine why aspace_json was nil after save when it was fetched successfully
        allow(po).to receive(:aspace_json).and_return(JSON.parse(File.read(File.join(fixture_path, "aspace", "AS-781086.json"))))
        expect(po.bib).to eq('4320085')
        expect(po.aspace_uri).to eq('/repositories/12/archival_objects/781086')
      end
      it 'can create a parent_object' do
        expect do
          batch_process.file = no_oid_parent
          batch_process.save
        end.to change { ParentObject.count }.from(0).to(1)
        po = ParentObject.first
        # TODO: determine why aspace_json was nil after save when it was fetched successfully
        allow(po).to receive(:aspace_json).and_return(JSON.parse(File.read(File.join(fixture_path, "aspace", "AS-2019479.json"))))
        expect(po.oid).not_to be_nil
      end
      context 'with detailed csv data' do
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
          expect(batch_process.batch_ingest_events[0].reason).to eq('Skipping row [2]. Process failed. Permission Set with Key: [] missing or nonexistent.')
        end
        it 'fails creating an OwP parent_object if user does not have admin privelages' do
          user.remove_role('administrator', permission_set)
          expect do
            batch_process.file = create_owp_parent
            batch_process.save
          end.not_to change { ParentObject.count }
          expect(batch_process.batch_ingest_events[0].reason).to eq('Skipping row [2] because user does not have edit permissions for this Permission Set: Permission Label')
        end
      end

      context 'with minimal csv data' do
        it 'fails when an OwP parent_object with no Permission Set key is submitted' do
          expect do
            batch_process.file = mini_create_owp_parent
            batch_process.save
          end.not_to change { ParentObject.count }
          expect(batch_process.batch_ingest_events[0].reason).to eq('Skipping row [2]. Process failed. Permission Set with Key: [] missing or nonexistent.')
        end
      end
      it 'can fail when csv has no admin set' do
        expect do
          batch_process.file = no_admin_set
          batch_process.save
        end.not_to change { ParentObject.count }
        expect(batch_process.batch_ingest_events[0].reason).to eq('Skipping row [2] with unknown admin set [] for parent: ')
      end
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
    end
  end
end
