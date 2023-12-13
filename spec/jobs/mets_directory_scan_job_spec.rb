# frozen_string_literal: true
require 'rails_helper'

RSpec.describe MetsDirectoryScanJob, type: :job do
  before do
    allow(GoodJob).to receive(:preserve_job_records).and_return(true)
    ActiveJob::Base.queue_adapter = GoodJob::Adapter.new(execution_mode: :inline)
  end

  let(:mets_directory_scan_job) { MetsDirectoryScanJob.new }

  it 'increments the job queue by one' do
    mets_directory_scan_job = described_class.perform_later
    expect(mets_directory_scan_job.instance_variable_get(:@successfully_enqueued)).to be true
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
