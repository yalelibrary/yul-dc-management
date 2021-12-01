# frozen_string_literal: true
require 'rails_helper'

RSpec.describe MetsDirectoryScanJob, type: :job do
  def queue_adapter_for_test
    ActiveJob::QueueAdapters::DelayedJobAdapter.new
  end

  let(:mets_directory_scan_job) { MetsDirectoryScanJob.new }

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

  it "has correct priority" do
    expect(mets_directory_scan_job.default_priority).to eq(100)
  end

  it "has correct queue" do
    expect(mets_directory_scan_job.queue_name).to eq('default')
  end
end
