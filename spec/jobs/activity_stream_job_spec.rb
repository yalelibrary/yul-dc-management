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
      new_time = Time.local(2021, 11, 5, 12, 0, 0)
      Timecop.travel(new_time)
      expect(ActivityStreamLog.count).to eq 1
    end
  
  end
  
end