# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GeneratePtiffJob, type: :job, prep_metadata_sources: true, prep_admin_sets: true do
  before do
    allow(GoodJob).to receive(:preserve_job_records).and_return(true)
    ActiveJob::Base.queue_adapter = GoodJob::Adapter.new(execution_mode: :external)
  end

  let(:user) { FactoryBot.create(:user) }
  let(:batch_process) { FactoryBot.create(:batch_process, user: user) }
  let(:parent_object) { FactoryBot.create(:parent_object, oid: 2_004_628, authoritative_metadata_source: MetadataSource.first, admin_set: AdminSet.first) }
  let(:child_object) { FactoryBot.create(:child_object, oid: "456789", parent_object: parent_object) }
  let(:generate_ptiff_job) { described_class.perform_later(child_object) }

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
    it 'increments the job queue' do
      expect(generate_ptiff_job.instance_variable_get(:@successfully_enqueued)).to be true
    end

    it 'increments the ptiff job queue when file not larger than 1GB' do
      expect(generate_ptiff_job.instance_variable_get(:@queue_name)).to eq 'ptiff'
    end

    it 'does not increment the large_ptiff job queue when file is smaller than 1GB' do
      expect(generate_ptiff_job.instance_variable_get(:@queue_name)).not_to eq 'large_ptiff'
    end

    it 'increments the job queue by one if needs_a_manifest is true' do
      allow(child_object.parent_object).to receive(:needs_a_manifest?).and_return(true)
      expect(generate_ptiff_job.instance_variable_get(:@successfully_enqueued)).to be true
    end

    it 'does not increment the job queue if ready_for_manifest is false' do
      allow(child_object.parent_object).to receive(:ready_for_manifest?).and_return(false)
      expect do
        GeneratePtiffJob.new.perform(child_object, batch_process)
      end.to change { GoodJob::Job.count }.by(0)
    end

    it 'raises an exception if convert to ptiff fails' do
      allow(child_object).to receive(:convert_to_ptiff!).and_return(false)
      expect do
        GeneratePtiffJob.new.perform(child_object, batch_process)
      end.to raise_error(RuntimeError)
    end
  end
end
