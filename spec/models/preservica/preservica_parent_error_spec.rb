# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Preservica::PreservicaObject, type: :model, prep_metadata_sources: true, prep_admin_sets: true do
  subject(:batch_process) { BatchProcess.new }
  let(:admin_set) { FactoryBot.create(:admin_set, key: 'brbl') }
  let(:user) { FactoryBot.create(:user, uid: "mk2525") }
  let(:sysadmin_user) { FactoryBot.create(:sysadmin_user) }
  let(:permission_set) { FactoryBot.create(:permission_set, key: 'psKey') }
  let(:preservica_parent) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "preservica", "preservica_parent.csv")) }
  let(:preservica_parent_no_source) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "preservica", "preservica_parent_no_source.csv")) }
  let(:preservica_parent_no_admin_set) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "preservica", "preservica_parent_no_admin_set.csv")) }
  let(:preservica_parent_no_permission_set) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "preservica", "preservica_owp_parent_no_permission_set.csv")) }
  let(:preservica_parent_with_permission_set) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "preservica", "preservica_owp_parent_with_permission_set.csv")) }

  around do |example|
    preservica_host = ENV['PRESERVICA_HOST']
    preservica_creds = ENV['PRESERVICA_CREDENTIALS']
    ENV['PRESERVICA_HOST'] = "testpreservica"
    ENV['PRESERVICA_CREDENTIALS'] = '{"sml": {"username":"xxxxx", "password":"xxxxx"}}'
    access_host = ENV['ACCESS_PRIMARY_MOUNT']
    ENV['ACCESS_PRIMARY_MOUNT'] = File.join("spec", "fixtures", "images", "access_primaries")
    perform_enqueued_jobs do
      example.run
    end
    ENV['PRESERVICA_HOST'] = preservica_host
    ENV['PRESERVICA_CREDENTIALS'] = preservica_creds
    ENV['ACCESS_PRIMARY_MOUNT'] = access_host
  end

  before do
    permission_set
    user.add_role(:editor, admin_set)
    stub_pdfs
    stub_preservica_aspace_single
    stub_preservica_login
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
    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(SetupMetadataJob).to receive(:perform).and_return(true)
    # rubocop:enable RSpec/AnyInstance
  end

  context 'with regular user' do
    before do
      batch_process.user_id = user.id
      login_as(:user)
    end

    it 'can send an error when Preservica credentials are not set' do
      expect do
        batch_process.file = preservica_parent
        batch_process.save
        expect(batch_process.batch_ingest_events.count).to eq(1)
        expect(batch_process.batch_ingest_events[0].reason).to eq("Skipping row [2] with admin set [brbl] for parent: 200000000. Preservica credentials not set for brbl.")
      end.not_to change { ParentObject.count }
    end

    it 'can send an error when no metadata source is set' do
      expect do
        batch_process.file = preservica_parent_no_source
        batch_process.save
        expect(batch_process.batch_ingest_events.count).to eq(1)
        expect(batch_process.batch_ingest_events[0].reason).to eq("Skipping row [2] with unknown source []. Source must be 'ils' or 'aspace'")
      end.not_to change { ParentObject.count }
    end
    # rubocop:disable Layout/LineLength
    it 'can send an error when no admin set is set' do
      expect do
        batch_process.file = preservica_parent_no_admin_set
        batch_process.save
        expect(batch_process.batch_ingest_events.count).to eq(1)
        expect(batch_process.batch_ingest_events[0].reason).to eq("The admin set code is missing or incorrect. Please ensure an admin_set value is in the correct spreadsheet column and that your 3 or 4 letter code is correct. ------------ Message from System: Skipping row [2] with unknown admin set [] for parent: 200000000")
      end.not_to change { ParentObject.count }
    end
    # rubocop:enable Layout/LineLength
    it 'can send an error when no permission set is set' do
      expect do
        batch_process.file = preservica_parent_no_permission_set
        batch_process.save
        expect(batch_process.batch_ingest_events.count).to eq(1)
        expect(batch_process.batch_ingest_events[0].reason).to eq("Skipping row [2] with unknown Permission Set with Key: [] for parent: 200000000")
      end.not_to change { ParentObject.count }
    end

    it 'can send an error when user does not have admin role on permission set' do
      expect do
        batch_process.file = preservica_parent_with_permission_set
        batch_process.save
        expect(batch_process.batch_ingest_events.count).to eq(1)
        expect(batch_process.batch_ingest_events[0].reason).to eq("Skipping row [2] because mk2525 does not have permission to update objects in Permission Set: Permission Label")
      end.not_to change { ParentObject.count }
    end
  end

  context 'with sysadmin user' do
    before do
      batch_process.user_id = sysadmin_user.id
      login_as(:sysadmin_user)
    end

    it 'can send an error when user does not have admin role on permission set' do
      expect do
        batch_process.file = preservica_parent_with_permission_set
        batch_process.save
        expect(batch_process.batch_ingest_events.count).to eq(1)
        expect(batch_process.batch_ingest_events[0].reason).to eq("Skipping row [2] because #{sysadmin_user.uid} does not have permission to update objects in Permission Set: Permission Label")
      end.not_to change { ParentObject.count }
    end

    it 'can send an error when user WAS an admin for permission set' do
      expect(sysadmin_user.has_role?(:administrator, permission_set)).to eq false
      sysadmin_user.add_role(:administrator, permission_set)
      expect(sysadmin_user.has_role?(:administrator, permission_set)).to eq true
      expect do
        batch_process.file = preservica_parent_with_permission_set
        batch_process.save
      end.to change { ParentObject.count }
      ParentObject.all.each(&:destroy)
      expect(ParentObject.count).to eq 0
      sysadmin_user.remove_role(:administrator, permission_set)
      expect(sysadmin_user.has_role?(:administrator, permission_set)).to eq false
      new_batch_process = BatchProcess.new
      new_batch_process.user_id = sysadmin_user.id
      expect do
        new_batch_process.file = preservica_parent_with_permission_set
        new_batch_process.save
        expect(new_batch_process.batch_ingest_events.count).to eq(1)
        expect(new_batch_process.batch_ingest_events[0].reason).to eq("Skipping row [2] because #{sysadmin_user.uid} does not have permission to update objects in Permission Set: Permission Label")
      end.not_to change { ParentObject.count }
    end
  end
end
