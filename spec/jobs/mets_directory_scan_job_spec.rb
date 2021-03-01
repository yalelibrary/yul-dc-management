# frozen_string_literal: true
require 'rails_helper'

RSpec.describe MetsDirectoryScanJob, type: :job do
  def queue_adapter_for_test
    ActiveJob::QueueAdapters::DelayedJobAdapter.new
  end

  it 'increments the job queue by one' do
    ActiveJob::Base.queue_adapter = :delayed_job
    expect do
      described_class.perform_later
    end.to change { Delayed::Job.count }.by(1)
  end

  it 'runs scanner when performed' do
    expect(MetsDirectoryScanner).to receive(:perform_scan).once
    described_class.new.perform
  end
end
