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

  xit 'job fails' do

  end

  describe 'time travel tests' do 
    before do
      Timecop.freeze(Date.today)
    end
  
    after do
      Timecop.return
    end
  
    it "increment job queue once" do
      byebug
      # Timecop.free
    end
  
  end

  it 'happens at 1am daily' do
    now = Time.current
    expect do
      travel 1.day
    end.to change { ActivityStreamLog.count }.by(1)
  end
end