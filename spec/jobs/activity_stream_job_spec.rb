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

  let(:metadata_job) { ActivityStreamJob.new }
  let(:like) { 'job_class LIKE ?' }
  let(:job_class) { '%ActivityStreamJob%' }

  it 'increments the job queue by one' do
    expect do
      ActivityStreamJob.perform_later(metadata_job)
    end.to change { GoodJob::Job.count }.by(1)
  end

  it 'increments the job queue by one for manual job' do
    expect do
      ActivityStreamManualJob.perform_later
    end.to change { GoodJob::Job.count }.by(1)
  end

  it 'job fails when not on VPN' do
    ActivityStreamReader.update
    expect(ActivityStreamLog.last.status).to include('Fail')
  end

  describe 'automated daily job' do
    before do
      Timecop.freeze(Time.zone.today)
    end

    after do
      Timecop.return
    end

    it 'increments job queue once per day' do
      now = Time.zone.today
      ActiveJob::Scheduler.start
      new_time = now + 1.day
      Timecop.travel(new_time)
      expect(GoodJob::Job.where(like, job_class).count).to eq 1
    end

    it 'automatic does not add another job when one is already running' do
      now = Time.zone.today
      ActiveJob::Scheduler.start
      new_time = now + 1.day
      Timecop.travel(new_time)
      expect(GoodJob::Job.where(like, job_class).count).to eq 1
      ActivityStreamJob.perform_now
      expect(ActivityStreamLog.last.status).to include('Fail')
    end

    it 'manual does not add another job when one is already running' do
      now = Time.zone.today
      ActiveJob::Scheduler.start
      new_time = now + 1.day
      Timecop.travel(new_time)
      expect(GoodJob::Job.where(like, job_class).count).to eq 1
      ActivityStreamManualJob.perform_now
      expect(ActivityStreamLog.last.status).to include('Fail')
    end
  end
end
