# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ActivityStreamJob, type: :job do
  before do
    allow(GoodJob).to receive(:preserve_job_records).and_return(true)
    ActiveJob::Base.queue_adapter = GoodJob::Adapter.new(execution_mode: :inline)
  end

  around do |example|
    original_mc_host = ENV['METADATA_CLOUD_HOST']
    ENV['METADATA_CLOUD_HOST'] = 'not-a-real-host'
    example.run
    ENV['METADATA_CLOUD_HOST'] = original_mc_host
  end

  let(:like) { 'job_class LIKE ?' }
  let(:job_class) { '%ActivityStreamJob%' }

  it 'enqueues the job' do
    activity_stream_job = described_class.perform_later(described_class.new)
    expect(activity_stream_job.instance_variable_get(:@successfully_enqueued)).to be true
  end

  it 'enqueues the job for manual job' do
    manual_activity_stream_job = ActivityStreamManualJob.perform_later
    expect(manual_activity_stream_job.instance_variable_get(:@successfully_enqueued)).to be true
  end

  it 'job fails when not on VPN' do
    ActivityStreamReader.update
    expect(ActivityStreamLog.last.status).to include('Fail')
  end

  describe 'automated daily job' do
    it 'increments job queue once per day' do
      expect(GoodJob::CronEntry.all.first.instance_variable_get(:@params)).to eq({ cron: "15 0 * * *", class: "ActivityStreamJob", key: :activity })
    end
  end
end
