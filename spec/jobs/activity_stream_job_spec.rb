# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ActivityStreamJob, type: :job do
  def queue_adapter_for_test
    ActiveJob::QueueAdapters::DelayedJobAdapter.new
  end

  around do |example|
    original_mc_host = ENV['METADATA_CLOUD_HOST']
    ENV['METADATA_CLOUD_HOST'] = 'not-a-real-host'
    ActiveJob::Base.queue_adapter = :delayed_job
    example.run
    ENV['METADATA_CLOUD_HOST'] = original_mc_host
  end

  let(:metadata_job) { ActivityStreamJob.new }
  let(:handler) { 'handler LIKE ?' }
  let(:job_class) { '%job_class: ActivityStreamJob%' }

  it 'increments the job queue by one' do
    expect do
      ActivityStreamJob.perform_later(metadata_job)
    end.to change { Delayed::Job.count }.by(1)
  end

  it 'increments the job queue by one for manual job' do
    expect do
      ActivityStreamManualJob.perform_later
    end.to change { Delayed::Job.count }.by(1)
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
      expect(Delayed::Job.where(handler, job_class).count).to eq 1
    end

    it 'automatic does not add another job when one is already running' do
      now = Time.zone.today
      ActiveJob::Scheduler.start
      new_time = now + 1.day
      Timecop.travel(new_time)
      expect(Delayed::Job.where(handler, job_class).count).to eq 1
      ActivityStreamJob.perform_now
      expect(ActivityStreamLog.last.status).to include('Fail')
    end

    it 'manual does not add another job when one is already running' do
      now = Time.zone.today
      ActiveJob::Scheduler.start
      new_time = now + 1.day
      Timecop.travel(new_time)
      expect(Delayed::Job.where(handler, job_class).count).to eq 1
      ActivityStreamManualJob.perform_now
      expect(ActivityStreamLog.last.status).to include('Fail')
    end
  end
end
