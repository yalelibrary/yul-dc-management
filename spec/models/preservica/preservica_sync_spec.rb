# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Preservica::PreservicaObject, type: :model, prep_metadata_sources: true, prep_admin_sets: true do
  subject(:batch_process) { BatchProcess.new }
  let(:admin_set) { FactoryBot.create(:admin_set, key: 'brbl') }
  let(:admin_set_sml) { FactoryBot.create(:admin_set, key: 'sml') }
  let(:user) { FactoryBot.create(:user, uid: "mk2525") }
  let(:preservica_parent_with_children) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "preservica", "preservica_parent_with_children.csv")) }
  let(:preservica_sync_invalid) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "preservica", "preservica_sync_invalid.csv")) }
  let(:preservica_sync) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "preservica", "preservica_sync.csv")) }

  around do |example|
    preservica_host = ENV['PRESERVICA_HOST']
    preservica_creds = ENV['PRESERVICA_CREDENTIALS']
    ENV['PRESERVICA_HOST'] = "testpreservica"
    ENV['PRESERVICA_CREDENTIALS'] = '{"brbl": {"username":"xxxxx", "password":"xxxxx"}}'
    access_host = ENV['ACCESS_MASTER_MOUNT']
    ENV['ACCESS_MASTER_MOUNT'] = File.join("spec", "fixtures", "images", "access_masters")
    perform_enqueued_jobs do
      example.run
    end
    ENV['PRESERVICA_HOST'] = preservica_host
    ENV['PRESERVICA_CREDENTIALS'] = preservica_creds
    ENV['ACCESS_MASTER_MOUNT'] = access_host
  end

  before do
    login_as(:user)
    batch_process.user_id = user.id
    stub_preservica_aspace_single
    stub_preservica_login
    fixtures = %w[preservica/api/entity/structural-objects/7fe35e8c-c21a-444a-a2e2-e3c926b519c5/children
                  preservica/api/entity/information-objects/1e42a2bb-8953-41b6-bcc3-1a19c86a5e3r/representations
                  preservica/api/entity/information-objects/1e42a2bb-8953-41b6-bcc3-1a19c86a5e3r/representations/Access-2
                  preservica/api/entity/information-objects/1e42a2bb-8953-41b6-bcc3-1a19c86a5e3r/representations/Preservation-1
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b486/generations
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b486/generations/1
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b486/generations/1/bitstreams/1
                  preservica/api/entity/information-objects/1e42a2bb-8953-41b6-bcc3-1a19c86a5e3d/representations
                  preservica/api/entity/information-objects/1e42a2bb-8953-41b6-bcc3-1a19c86a5e3d/representations/Access-2
                  preservica/api/entity/information-objects/1e42a2bb-8953-41b6-bcc3-1a19c86a5e3d/representations/Preservation-1
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b489/generations
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b489/generations/1
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b489/generations/1/bitstreams/1
                  preservica/api/entity/information-objects/f44ba97e-af2b-498e-b118-ed1247822f44/representations
                  preservica/api/entity/information-objects/f44ba97e-af2b-498e-b118-ed1247822f44/representations/Access-2
                  preservica/api/entity/information-objects/f44ba97e-af2b-498e-b118-ed1247822f44/representations/Preservation-1
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

  context 'user with permission' do
    before do
      user.add_role(:editor, admin_set)
      login_as(:user)
    end

    it 'can sync child objects' do
      File.delete("spec/fixtures/images/access_masters/00/01/20/00/00/00/200000001.tif") if File.exist?("spec/fixtures/images/access_masters/00/01/20/00/00/00/200000001.tif")
      File.delete("spec/fixtures/images/access_masters/00/02/20/00/00/00/200000002.tif") if File.exist?("spec/fixtures/images/access_masters/00/02/20/00/00/00/200000002.tif")
      File.delete("spec/fixtures/images/access_masters/00/03/20/00/00/00/200000003.tif") if File.exist?("spec/fixtures/images/access_masters/00/03/20/00/00/00/200000003.tif")
      File.delete("spec/fixtures/images/access_masters/00/04/20/00/00/00/200000004.tif") if File.exist?("spec/fixtures/images/access_masters/00/04/20/00/00/00/200000004.tif")
      File.delete("spec/fixtures/images/access_masters/00/05/20/00/00/00/200000005.tif") if File.exist?("spec/fixtures/images/access_masters/00/05/20/00/00/00/200000005.tif")
      File.delete("spec/fixtures/images/access_masters/00/06/20/00/00/00/200000006.tif") if File.exist?("spec/fixtures/images/access_masters/00/06/20/00/00/00/200000006.tif")

      allow(S3Service).to receive(:s3_exists?).and_return(false)
      expect(File.exist?("spec/fixtures/images/access_masters/00/01/20/00/00/00/200000001.tif")).to be false
      expect(File.exist?("spec/fixtures/images/access_masters/00/02/20/00/00/00/200000002.tif")).to be false
      expect(File.exist?("spec/fixtures/images/access_masters/00/03/20/00/00/00/200000003.tif")).to be false
      expect(File.exist?("spec/fixtures/images/access_masters/00/04/20/00/00/00/200000004.tif")).to be false
      expect(File.exist?("spec/fixtures/images/access_masters/00/05/20/00/00/00/200000005.tif")).to be false
      expect(File.exist?("spec/fixtures/images/access_masters/00/06/20/00/00/00/200000006.tif")).to be false
      expect do
        batch_process.file = preservica_parent_with_children
        batch_process.save
      end.to change { ChildObject.count }.from(0).to(3)
      po_first = ParentObject.first
      co_first = ChildObject.first
      expect(co_first.oid).to be 200_000_001
      expect(co_first.parent_object_oid).to be 200_000_000
      expect(co_first.order).to be 1
      co_last = ChildObject.last
      expect(co_last.order).to be 3
      expect(po_first.last_preservica_update).not_to be nil
      expect(co_first.preservica_content_object_uri).to eq "https://preservica-dev-v6.library.yale.edu/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b486"
      expect(co_first.preservica_generation_uri).to eq "https://preservica-dev-v6.library.yale.edu/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b486/generations/1"
      expect(co_first.preservica_bitstream_uri).to eq "/home/app/webapp/spec/fixtures/preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b486/generations/1/bitstreams/1"
      expect(co_first.sha512_checksum).to eq "1932c08c4670d5010fac6fa363ad5d9be7a4e7d743757ba5eefbbe8e3f9b2fb89b1604c1e527cfae6f47a91a60845268e91d2723aa63a90dd4735f75017569f7"
      expect(File.exist?("spec/fixtures/images/access_masters/00/01/20/00/00/00/200000001.tif")).to be true
      expect(File.exist?("spec/fixtures/images/access_masters/00/02/20/00/00/00/200000002.tif")).to be true
      expect(File.exist?("spec/fixtures/images/access_masters/00/03/20/00/00/00/200000003.tif")).to be true
      expect(co_first.ptiff_conversion_at.present?).to be_truthy
      File.delete("spec/fixtures/images/access_masters/00/01/20/00/00/00/200000001.tif") if File.exist?("spec/fixtures/images/access_masters/00/01/20/00/00/00/200000001.tif")
      File.delete("spec/fixtures/images/access_masters/00/02/20/00/00/00/200000002.tif") if File.exist?("spec/fixtures/images/access_masters/00/02/20/00/00/00/200000002.tif")
      File.delete("spec/fixtures/images/access_masters/00/03/20/00/00/00/200000003.tif") if File.exist?("spec/fixtures/images/access_masters/00/03/20/00/00/00/200000003.tif")
      co = ChildObject.last
      co.delete
      expect(ChildObject.count).to be 2

      sync_batch_process = BatchProcess.new(batch_action: 'sync from preservica', user: user)
      expect do
        sync_batch_process.file = preservica_sync
        sync_batch_process.save!
      end.to change { ChildObject.count }.from(2).to(3)
      expect(File.exist?("spec/fixtures/images/access_masters/00/04/20/00/00/00/200000004.tif")).to be true
      expect(File.exist?("spec/fixtures/images/access_masters/00/05/20/00/00/00/200000005.tif")).to be true
      expect(File.exist?("spec/fixtures/images/access_masters/00/06/20/00/00/00/200000006.tif")).to be true
      File.delete("spec/fixtures/images/access_masters/00/04/20/00/00/00/200000004.tif") if File.exist?("spec/fixtures/images/access_masters/00/04/20/00/00/00/200000004.tif")
      File.delete("spec/fixtures/images/access_masters/00/05/20/00/00/00/200000005.tif") if File.exist?("spec/fixtures/images/access_masters/00/05/20/00/00/00/200000005.tif")
      File.delete("spec/fixtures/images/access_masters/00/06/20/00/00/00/200000006.tif") if File.exist?("spec/fixtures/images/access_masters/00/06/20/00/00/00/200000006.tif")
    end

    it 'can recognize when child object count and order is the same' do
      File.delete("spec/fixtures/images/access_masters/00/01/20/00/00/00/200000001.tif") if File.exist?("spec/fixtures/images/access_masters/00/01/20/00/00/00/200000001.tif")
      File.delete("spec/fixtures/images/access_masters/00/02/20/00/00/00/200000002.tif") if File.exist?("spec/fixtures/images/access_masters/00/02/20/00/00/00/200000002.tif")
      File.delete("spec/fixtures/images/access_masters/00/03/20/00/00/00/200000003.tif") if File.exist?("spec/fixtures/images/access_masters/00/03/20/00/00/00/200000003.tif")

      allow(S3Service).to receive(:s3_exists?).and_return(false)
      expect(File.exist?("spec/fixtures/images/access_masters/00/01/20/00/00/00/200000001.tif")).to be false
      expect(File.exist?("spec/fixtures/images/access_masters/00/02/20/00/00/00/200000002.tif")).to be false
      expect(File.exist?("spec/fixtures/images/access_masters/00/03/20/00/00/00/200000003.tif")).to be false
      expect do
        batch_process.file = preservica_parent_with_children
        batch_process.save
      end.to change { ChildObject.count }.from(0).to(3)
      expect(File.exist?("spec/fixtures/images/access_masters/00/01/20/00/00/00/200000001.tif")).to be true
      expect(File.exist?("spec/fixtures/images/access_masters/00/02/20/00/00/00/200000002.tif")).to be true
      expect(File.exist?("spec/fixtures/images/access_masters/00/03/20/00/00/00/200000003.tif")).to be true
      File.delete("spec/fixtures/images/access_masters/00/01/20/00/00/00/200000001.tif") if File.exist?("spec/fixtures/images/access_masters/00/01/20/00/00/00/200000001.tif")
      File.delete("spec/fixtures/images/access_masters/00/02/20/00/00/00/200000002.tif") if File.exist?("spec/fixtures/images/access_masters/00/02/20/00/00/00/200000002.tif")
      File.delete("spec/fixtures/images/access_masters/00/03/20/00/00/00/200000003.tif") if File.exist?("spec/fixtures/images/access_masters/00/03/20/00/00/00/200000003.tif")

      sync_batch_process = BatchProcess.new(batch_action: 'sync from preservica', user: user)
      expect do
        sync_batch_process.file = preservica_sync
        sync_batch_process.save!
      end.not_to change { ChildObject.count }
      expect(sync_batch_process.batch_ingest_events_count).to eq 1
      expect(sync_batch_process.batch_ingest_events.last.reason).to eq('Child object count and order is the same.  No update needed.')
    end

    it 'can throw an error if parent object is not found' do
      File.delete("spec/fixtures/images/access_masters/00/01/20/00/00/00/200000001.tif") if File.exist?("spec/fixtures/images/access_masters/00/01/20/00/00/00/200000001.tif")
      File.delete("spec/fixtures/images/access_masters/00/02/20/00/00/00/200000002.tif") if File.exist?("spec/fixtures/images/access_masters/00/02/20/00/00/00/200000002.tif")
      File.delete("spec/fixtures/images/access_masters/00/03/20/00/00/00/200000003.tif") if File.exist?("spec/fixtures/images/access_masters/00/03/20/00/00/00/200000003.tif")

      allow(S3Service).to receive(:s3_exists?).and_return(false)
      expect(File.exist?("spec/fixtures/images/access_masters/00/01/20/00/00/00/200000001.tif")).to be false
      expect(File.exist?("spec/fixtures/images/access_masters/00/02/20/00/00/00/200000002.tif")).to be false
      expect(File.exist?("spec/fixtures/images/access_masters/00/03/20/00/00/00/200000003.tif")).to be false
      expect do
        batch_process.file = preservica_parent_with_children
        batch_process.save
      end.to change { ChildObject.count }.from(0).to(3)
      expect(File.exist?("spec/fixtures/images/access_masters/00/01/20/00/00/00/200000001.tif")).to be true
      expect(File.exist?("spec/fixtures/images/access_masters/00/02/20/00/00/00/200000002.tif")).to be true
      expect(File.exist?("spec/fixtures/images/access_masters/00/03/20/00/00/00/200000003.tif")).to be true
      File.delete("spec/fixtures/images/access_masters/00/01/20/00/00/00/200000001.tif") if File.exist?("spec/fixtures/images/access_masters/00/01/20/00/00/00/200000001.tif")
      File.delete("spec/fixtures/images/access_masters/00/02/20/00/00/00/200000002.tif") if File.exist?("spec/fixtures/images/access_masters/00/02/20/00/00/00/200000002.tif")
      File.delete("spec/fixtures/images/access_masters/00/03/20/00/00/00/200000003.tif") if File.exist?("spec/fixtures/images/access_masters/00/03/20/00/00/00/200000003.tif")

      sync_batch_process = BatchProcess.new(batch_action: 'sync from preservica', user: user)
      expect do
        sync_batch_process.file = preservica_sync_invalid
        sync_batch_process.save!
      end.not_to change { ChildObject.count }
      expect(sync_batch_process.batch_ingest_events_count).to be 1
      expect(sync_batch_process.batch_ingest_events.last.reason).to eq('Parent OID: 12345 not found in database')
    end

    it 'can throw an error if parent object is a redirected parent' do
      allow(S3Service).to receive(:s3_exists?).and_return(false)
      parent_object = ParentObject.new(oid: 12_345, admin_set: AdminSet.find_by_key('brbl'), redirect_to: "https://collections.library.yale.edu/catalog/123")
      parent_object.save

      sync_batch_process = BatchProcess.new(batch_action: 'sync from preservica', user: user)
      expect do
        sync_batch_process.file = preservica_sync_invalid
        sync_batch_process.save!
      end.not_to change { ChildObject.count }
      expect(sync_batch_process.batch_ingest_events_count).to be 1
      expect(sync_batch_process.batch_ingest_events.last.reason).to eq('Parent OID: 12345 is a redirected parent object')
    end

    it 'can throw an error if parent object does not have a preservica_uri' do
      allow(S3Service).to receive(:s3_exists?).and_return(false)
      parent_object = ParentObject.new(oid: 12_345, admin_set: AdminSet.find_by_key('brbl'))
      parent_object.save

      sync_batch_process = BatchProcess.new(batch_action: 'sync from preservica', user: user)
      expect do
        sync_batch_process.file = preservica_sync_invalid
        sync_batch_process.save!
      end.not_to change { ChildObject.count }
      expect(sync_batch_process.batch_ingest_events_count).to be 1
      expect(sync_batch_process.batch_ingest_events.last.reason).to eq('Parent OID: 12345 does not have a Preservica URI')
    end

    it 'can throw an error if parent object does not have a digital object source' do
      allow(S3Service).to receive(:s3_exists?).and_return(false)
      parent_object = ParentObject.new(oid: 12_345, admin_set: AdminSet.find_by_key('brbl'), preservica_uri: "/")
      parent_object.save

      sync_batch_process = BatchProcess.new(batch_action: 'sync from preservica', user: user)
      expect do
        sync_batch_process.file = preservica_sync_invalid
        sync_batch_process.save!
      end.not_to change { ChildObject.count }
      expect(sync_batch_process.batch_ingest_events_count).to be 1
      expect(sync_batch_process.batch_ingest_events.last.reason).to eq('Parent OID: 12345 does not have a Preservica digital object source')
    end

    it 'can throw an error if parent object does not have a preservica representation name' do
      allow(S3Service).to receive(:s3_exists?).and_return(false)
      parent_object = ParentObject.new(oid: 12_345, admin_set: AdminSet.find_by_key('brbl'), preservica_uri: "/", digital_object_source: "Preservica")
      parent_object.save

      sync_batch_process = BatchProcess.new(batch_action: 'sync from preservica', user: user)
      expect do
        sync_batch_process.file = preservica_sync_invalid
        sync_batch_process.save!
      end.not_to change { ChildObject.count }
      expect(sync_batch_process.batch_ingest_events_count).to be 1
      expect(sync_batch_process.batch_ingest_events.last.reason).to eq('Parent OID: 12345 does not have a Preservica representation name')
    end

    it 'can throw an error if parent object does not have an admin set with preservica credentials' do
      allow(S3Service).to receive(:s3_exists?).and_return(false)
      parent_object = ParentObject.new(oid: 12_345, admin_set: AdminSet.find_by_key('sml'), preservica_uri: "/", digital_object_source: "Preservica", preservica_representation_name: "Preservation-1")
      parent_object.save

      sync_batch_process = BatchProcess.new(batch_action: 'sync from preservica', user: user)
      expect do
        sync_batch_process.file = preservica_sync_invalid
        sync_batch_process.save!
      end.not_to change { ChildObject.count }
      expect(sync_batch_process.batch_ingest_events_count).to be 1
      expect(sync_batch_process.batch_ingest_events.last.reason).to eq('Admin set sml does not have Preservica credentials set')
    end
  end

  context 'user without permission' do
    before do
      user.remove_role(:editor)
      login_as(:user)
    end

    it 'can throw an error if user does not have permission on parent object' do
      allow(S3Service).to receive(:s3_exists?).and_return(false)
      parent_object = ParentObject.new(oid: 12_345, admin_set: AdminSet.find_by_key('brbl'), preservica_uri: "/", digital_object_source: "Preservica", preservica_representation_name: "Preservation-1")
      parent_object.save

      sync_batch_process = BatchProcess.new(batch_action: 'sync from preservica', user: user)
      expect do
        sync_batch_process.file = preservica_sync_invalid
        sync_batch_process.save!
      end.not_to change { ChildObject.count }
      expect(sync_batch_process.batch_ingest_events_count).to be 1
      expect(sync_batch_process.batch_ingest_events.last.reason).to eq('Skipping row with parent oid: 12345, user does not have permission to update')
    end
  end
end
