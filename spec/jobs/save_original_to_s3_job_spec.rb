# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SaveOriginalToS3Job, type: :job do
  def queue_adapter_for_test
    ActiveJob::QueueAdapters::DelayedJobAdapter.new
  end
  let(:user) { FactoryBot.create(:user) }
  let(:batch_process) { FactoryBot.create(:batch_process, user: user) }
  let(:metadata_source) { FactoryBot.create(:metadata_source) }
  let(:parent_object_private) { FactoryBot.create(:parent_object, oid: 2_004_628, authoritative_metadata_source: metadata_source, visibility: "Private") }
  let(:child_object) { FactoryBot.create(:child_object, oid: "456789", parent_object: parent_object_private) }
  let(:save_to_s3_job) { SaveOriginalToS3Job.new }
  let(:parent_object_with_authoritative_json) { FactoryBot.build(:parent_object, oid: '16712419', ladybird_json: JSON.parse(File.read(File.join(fixture_path, "ladybird", "16712419.json")))) }

  around do |example|
    original_image_bucket = ENV["S3_SOURCE_BUCKET_NAME"]
    ENV["S3_SOURCE_BUCKET_NAME"] = "not-a-real-bucket"
    example.run
    ENV["S3_SOURCE_BUCKET_NAME"] = original_image_bucket
  end

  before do
    stub_request(:put, "https://not-a-real-bucket.s3.amazonaws.com/download/tiff/89/45/67/89/456789.tif")
        .to_return(status: 200)
    stub_request(:head, "https://not-a-real-bucket.s3.amazonaws.com/originals/89/45/67/89/456789.tif")
        .to_return(status: 200, body: "", headers: {})
    stub_request(:head, "https://not-a-real-bucket.s3.amazonaws.com/ptiffs/89/45/67/89/456789.tif")
        .to_return(status: 200, body: "", headers: {})
    child_object
  end

  describe 'save to S3 job' do
    it 'throws exception with Private or Redirect visibility' do
      expect do
        save_to_s3_job.perform(child_object.oid)
      end.to raise_error("Not copying image from #{parent_object_private.oid}. Parent object must have Public or Yale Community Only visibility.")
    end
    it 'throws exception when file is already in S3' do
      parent_object_private.visibility = "Public"
      parent_object_private.save
      expect do
        save_to_s3_job.perform(child_object.oid)
      end.to raise_error("Not copying image. Child object #{child_object.oid} already exists on S3.")
    end
    it "has correct priority" do
      expect(save_to_s3_job.default_priority).to eq(100)
    end
    it "can save a file to S3" do
      # allow(S3Service).to receive(:remote_metadata).and_return(parent_object_with_authoritative_json)
      save_to_s3_job.perform(child_object.oid)
    end
  end
end
