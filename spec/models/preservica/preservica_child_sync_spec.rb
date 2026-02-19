# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Preservica::PreservicaObject, type: :model, prep_metadata_sources: true, prep_admin_sets: true do
  subject(:batch_process) { BatchProcess.new }
  let(:admin_set) { FactoryBot.create(:admin_set, key: 'brbl') }
  let(:admin_set_sml) { FactoryBot.create(:admin_set, key: 'sml') }
  let(:user) { FactoryBot.create(:user, uid: "mk2525") }
  let(:aspace_parent) do
    FactoryBot.create(:parent_object, oid: 200_000_000, authoritative_metadata_source_id: 3, aspace_uri: '/repositories/11/archival_objects/214638', admin_set: AdminSet.find_by_key('brbl'))
  end
  let(:sml_parent) { FactoryBot.create(:parent_object, oid: 12_345, admin_set: AdminSet.find_by_key('sml')) }
  let(:co_1) do
    FactoryBot.create(:child_object, oid: 1_002_533, parent_object: aspace_parent, order: 1, label: 'original first label', caption: 'original first caption',
                                     checksum: 'c314697a5b0fd444e26e7c12a1d8d487545dacfc')
  end
  let(:co_2) do
    FactoryBot.create(:child_object, oid: 1_002_534, parent_object: aspace_parent, order: 2, label: 'original second label', caption: 'original second caption',
                                     checksum: '466727ad4851a2586ad9979613a56c7c137d7e8b')
  end
  let(:co_3) do
    FactoryBot.create(:child_object, oid: 1_002_535, parent_object: aspace_parent, order: 3, label: 'original third label', caption: 'original third caption',
                                     checksum: 'f3755c5d9e086b4522a0d3916e9a0bfcbd47564e')
  end
  let(:ptf_1) { PyramidalTiff.new(co_1) }
  let(:ptf_2) { PyramidalTiff.new(co_2) }
  let(:ptf_3) { PyramidalTiff.new(co_3) }
  let(:preservica_reingest_invalid) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "preservica", "preservica_reingest_invalid.csv")) }
  let(:preservica_reingest) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "preservica", "preservica_reingest.csv")) }

  around do |example|
    preservica_host = ENV['PRESERVICA_HOST']
    preservica_creds = ENV['PRESERVICA_CREDENTIALS']
    ENV['PRESERVICA_HOST'] = "testpreservica"
    ENV['PRESERVICA_CREDENTIALS'] = '{"brbl": {"username":"xxxxx", "password":"xxxxx"}}'
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
    login_as(:user)
    batch_process.user_id = user.id
    stub_metadata_cloud('AS-200000000', 'aspace')
    stub_pdfs
    aspace_parent
    co_1
    co_2
    co_3
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
    stub_request(:get, "https://yale-test-image-samples.s3.amazonaws.com/originals/1002533.tif")
      .to_return(status: 200, body: File.open('spec/fixtures/images/sample.tiff', 'rb'))
    stub_request(:head, "https://yale-test-image-samples.s3.amazonaws.com/originals/1002533.tif")
      .to_return(status: 200)
    stub_request(:put, "https://yale-test-image-samples.s3.amazonaws.com/ptiffs/33/10/02/53/1002533.tif")
      .to_return(status: 200)
    stub_request(:get, "https://yale-test-image-samples.s3.amazonaws.com/originals/1002534.tif")
      .to_return(status: 200, body: File.open('spec/fixtures/images/sample.tiff', 'rb'))
    stub_request(:head, "https://yale-test-image-samples.s3.amazonaws.com/originals/1002534.tif")
      .to_return(status: 200)
    stub_request(:put, "https://yale-test-image-samples.s3.amazonaws.com/ptiffs/34/10/02/53/1002534.tif")
      .to_return(status: 200)
    stub_request(:get, "https://yale-test-image-samples.s3.amazonaws.com/originals/1002535.tif")
      .to_return(status: 200, body: File.open('spec/fixtures/images/sample.tiff', 'rb'))
    stub_request(:head, "https://yale-test-image-samples.s3.amazonaws.com/originals/1002535.tif")
      .to_return(status: 200)
    stub_request(:put, "https://yale-test-image-samples.s3.amazonaws.com/ptiffs/03/35/10/02/53/1002535.tif")
      .to_return(status: 200)
  end

  context 'user with permission' do
    before do
      user.add_role(:editor, admin_set)
      login_as(:user)
    end

    it 'can reingest child objects and keep oids, captions and labels but replace image source location' do
      allow(S3Service).to receive(:s3_exists?).and_return(false)
      expect(ParentObject.count).to eq 1
      expect(ChildObject.count).to eq 3
      po_first = ParentObject.first
      co_first = ChildObject.first
      expect(co_first.oid).to eq 1_002_533
      expect(co_first.caption).to eq 'original first caption'
      expect(co_first.label).to eq 'original first label'
      expect(co_first.checksum).to eq 'c314697a5b0fd444e26e7c12a1d8d487545dacfc'
      expect(po_first.last_preservica_update).to be nil
      expect(ptf_1.access_primary_path).to eq "spec/fixtures/images/access_primaries/03/33/10/02/53/1002533.tif"
      expect(ptf_2.access_primary_path).to eq "spec/fixtures/images/access_primaries/03/34/10/02/53/1002534.tif"
      expect(ptf_3.access_primary_path).to eq "spec/fixtures/images/access_primaries/03/35/10/02/53/1002535.tif"
      reingest_batch_process = BatchProcess.new(batch_action: 'update parent objects', user: user)
      expect do
        reingest_batch_process.file = preservica_reingest
        reingest_batch_process.save!
      end.not_to change { ChildObject.count }
      po_first = ParentObject.first
      co_first = ChildObject.first
      co_second = ChildObject.all[1]
      co_third = ChildObject.last

      expect(po_first.last_preservica_update).not_to be nil
      expect(co_first.last_preservica_update).not_to be nil
      expect(co_first.sha512_checksum).to eq '1932c08c4670d5010fac6fa363ad5d9be7a4e7d743757ba5eefbbe8e3f9b2fb89b1604c1e527cfae6f47a91a60845268e91d2723aa63a90dd4735f75017569f7'
      expect(co_first.oid).to eq 1_002_533
      expect(co_first.caption).to eq 'original first caption'
      expect(co_first.label).to eq 'original first label'
      expect(co_first.order).to eq 1
      ptf_1_post = PyramidalTiff.new(co_first)
      ptf_2_post = PyramidalTiff.new(co_second)
      ptf_3_post = PyramidalTiff.new(co_third)
      expect(ptf_1_post.access_primary_path).to eq "spec/fixtures/images/access_primaries/03/33/10/02/53/1002533.tif"
      expect(ptf_2_post.access_primary_path).to eq "spec/fixtures/images/access_primaries/03/34/10/02/53/1002534.tif"
      expect(ptf_3_post.access_primary_path).to eq "spec/fixtures/images/access_primaries/03/35/10/02/53/1002535.tif"
      expect(File.exist?("spec/fixtures/images/access_primaries/03/33/10/02/53/1002533.tif")).to be true
      expect(File.exist?("spec/fixtures/images/access_primaries/03/34/10/02/53/1002534.tif")).to be true
      expect(File.exist?("spec/fixtures/images/access_primaries/03/35/10/02/53/1002535.tif")).to be true
    end
  end

  context 'user without permission' do
    before do
      user.remove_role(:editor)
      login_as(:user)
    end

    it 'can throw an error if user does not have permission on parent object' do
      allow(S3Service).to receive(:s3_exists?).and_return(false)
      parent_object = ParentObject.new(oid: 12_345, admin_set: AdminSet.find_by_key('brbl'))
      parent_object.save

      reingest_batch_process = BatchProcess.new(batch_action: 'update parent objects', user: user)
      expect do
        reingest_batch_process.file = preservica_reingest_invalid
        reingest_batch_process.save!
      end.not_to change { ChildObject.count }
      expect(reingest_batch_process.batch_ingest_events_count).to be 1
      expect(reingest_batch_process.batch_ingest_events.last.reason).to eq('Skipping row [2] with parent oid: 12345, user does not have permission to update.')
    end
  end
end
