# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SaveOriginalToS3Job, type: :job do
  def queue_adapter_for_test
    ActiveJob::QueueAdapters::DelayedJobAdapter.new
  end
  let(:user) { FactoryBot.create(:user) }
  let(:batch_process) { FactoryBot.create(:batch_process, user: user) }
  let(:metadata_source) { FactoryBot.create(:metadata_source) }
  let(:parent_object_private) { FactoryBot.create(:parent_object, oid: 2_004_628, authoritative_metadata_source: metadata_source, visibility: 'Private') }
  let(:child_object) { FactoryBot.create(:child_object, oid: '456789', parent_object: parent_object_private) }
  let(:save_to_s3_job) { SaveOriginalToS3Job.new }
  let(:parent_object_with_authoritative_json) do
    FactoryBot.build(:parent_object,
                     oid: '16712419',
                     visibility: 'Public',
                     ladybird_json: JSON.parse(File.read(File.join(fixture_path, 'ladybird', '16712419.json'))))
  end
  let(:child_object_with_authoritative_json) { FactoryBot.create(:child_object, oid: '345678', parent_object: parent_object_with_authoritative_json) }

  around do |example|
    original_image_bucket = ENV['S3_SOURCE_BUCKET_NAME']
    original_download_bucket = ENV['S3_DOWNLOAD_BUCKET_NAME']
    original_access_master_mount = ENV["ACCESS_MASTER_MOUNT"]
    ENV['S3_SOURCE_BUCKET_NAME'] = 'not-a-real-bucket'
    ENV['S3_DOWNLOAD_BUCKET_NAME'] = 'fake-download-bucket'
    ENV["ACCESS_MASTER_MOUNT"] = File.join(fixture_path, "images/ptiff_images")
    example.run
    ENV['S3_SOURCE_BUCKET_NAME'] = original_image_bucket
    ENV['S3_DOWNLOAD_BUCKET_NAME'] = original_download_bucket
    ENV["ACCESS_MASTER_MOUNT"] = original_access_master_mount
  end

  before do
    stub_request(:head, 'https://fake-download-bucket.s3.amazonaws.com/download/tiff/78/34/56/78/345678.tif')
        .to_return(status: 200, body: '', headers: {})
    stub_request(:head, 'https://not-a-real-bucket.s3.amazonaws.com/originals/78/34/56/78/345678.tif')
        .to_return(status: 200, body: '', headers: {})
    stub_request(:head, 'https://not-a-real-bucket.s3.amazonaws.com/ptiffs/78/34/56/78/345678.tif')
        .to_return(status: 200, body: '', headers: {})
    stub_request(:put, 'https://fake-download-bucket.s3.amazonaws.com/download/tiff/89/45/67/89/456789.tif')
        .to_return(status: 200, body: '', headers: {})
    stub_request(:head, 'https://fake-download-bucket.s3.amazonaws.com/download/tiff/89/45/67/89/456789.tif')
        .to_return(status: 404, body: '', headers: {}).times(1).then.to_return(status: 200, body: '', headers: {})
    stub_request(:head, 'https://not-a-real-bucket.s3.amazonaws.com/originals/89/45/67/89/456789.tif')
        .to_return(status: 200, body: '', headers: {})
    stub_request(:head, 'https://not-a-real-bucket.s3.amazonaws.com/ptiffs/89/45/67/89/456789.tif')
        .to_return(status: 200, body: '', headers: {})
    child_object
  end

  describe 'save to S3 job' do
    it 'throws exception with Private or Redirect visibility' do
      expect do
        save_to_s3_job.perform(child_object.oid)
      end.to raise_error(an_instance_of(RuntimeError).and(having_attributes(message: 'Not copying image from 2004628. Parent object must have Public or Yale Community Only visibility.')))
    end
    it 'throws exception when file is already in S3' do
      expect do
        save_to_s3_job.perform(child_object_with_authoritative_json.oid)
      end.to raise_error(an_instance_of(RuntimeError).and(having_attributes(message: "Not copying image. Child object #{child_object_with_authoritative_json.oid} already exists on S3.")))
    end
    it 'has correct priority' do
      expect(save_to_s3_job.default_priority).to eq(100)
    end
    it 'can save a file to S3' do
      parent_object_private.visibility = 'Public'
      parent_object_private.save
      save_to_s3_job.perform(child_object.oid)
      expect(S3Service.s3_exists_for_download?('download/tiff/89/45/67/89/456789.tif')).to be_truthy
    end
  end
end
