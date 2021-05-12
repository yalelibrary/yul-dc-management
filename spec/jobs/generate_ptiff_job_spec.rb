# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GeneratePtiffJob, type: :job do
  def queue_adapter_for_test
    ActiveJob::QueueAdapters::DelayedJobAdapter.new
  end
  let(:user) { FactoryBot.create(:user) }
  let(:batch_process) { FactoryBot.create(:batch_process, user: user) }
  let(:metadata_source) { FactoryBot.create(:metadata_source) }
  let(:parent_object) { FactoryBot.create(:parent_object, oid: 2_004_628, authoritative_metadata_source: metadata_source) }
  let(:child_object) { FactoryBot.create(:child_object, oid: "456789", parent_object: parent_object) }
  let(:generate_ptiff_job) { described_class.new }

  around do |example|
    original_image_bucket = ENV["S3_SOURCE_BUCKET_NAME"]
    ENV["S3_SOURCE_BUCKET_NAME"] = "not-a-real-bucket"
    example.run
    ENV["S3_SOURCE_BUCKET_NAME"] = original_image_bucket
  end

  before do
    stub_request(:head, "https://not-a-real-bucket.s3.amazonaws.com/originals/89/45/67/89/456789.tif")
      .to_return(status: 200, body: "", headers: {})
    stub_request(:head, "https://not-a-real-bucket.s3.amazonaws.com/ptiffs/89/45/67/89/456789.tif")
      .to_return(status: 200, body: "", headers: {})
    allow(child_object).to receive(:convert_to_ptiff!).and_return(true)
    child_object
  end

  describe 'generate ptiff job' do
    it 'increments the job queue by one' do
      expect do
        described_class.perform_later(child_object)
      end.to change { Delayed::Job.count }.by(1)
    end

    it 'increments the job queue by one if needs_a_manifest is true' do
      allow(child_object.parent_object).to receive(:needs_a_manifest?).and_return(true)
      expect do
        generate_ptiff_job.perform(child_object, batch_process)
      end.to change { Delayed::Job.count }.by(1)
      expect(Delayed::Job.last.handler).to match(/GenerateManifestJob/)
    end

    it 'does not increment the job queue if ready_for_manifest is false' do
      allow(child_object.parent_object).to receive(:ready_for_manifest?).and_return(false)
      expect do
        generate_ptiff_job.perform(child_object, batch_process)
      end.to change { Delayed::Job.count }.by(0)
    end

    it 'raises an exception if convert to ptiff fails' do
      allow(child_object).to receive(:convert_to_ptiff!).and_return(false)
      expect do
        generate_ptiff_job.perform(child_object, batch_process)
      end.to raise_error
    end
  end
end
