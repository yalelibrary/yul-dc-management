# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ActivityStreamJob, type: :job do
  def queue_adapter_for_test
    ActiveJob::QueueAdapters::DelayedJobAdapter.new
  end

  let(:metadata_job) { ActivityStreamJob.new }

  it 'increments the job queue by one' do
    ActiveJob::Base.queue_adapter = :delayed_job
    expect do
      ActivityStreamJob.perform_later(metadata_job)
    end.to change { Delayed::Job.count }.by(1)
  end

  it 'job fails when not on VPN' do
    expect do
      ActivityStreamReader.update
    end.to raise_error HTTP::ConnectionError
  end

  describe 'automated daily job' do
    before do
      Timecop.freeze(Time.zone.today)
    end

    after do
      Timecop.return
    end

    it "increments job queue once per day" do
      now = Time.zone.today
      ActiveJob::Scheduler.start
      new_time = Time.zone.local(now.year, now.month, now.day + 1, 12, 0, 0)
      Timecop.travel(new_time)
      expect(Delayed::Job.count).to eq 1
    end
  end
end
