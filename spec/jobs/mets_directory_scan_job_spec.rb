# frozen_string_literal: true
require 'rails_helper'

RSpec.describe MetsDirectoryScanJob, type: :job do
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
    expect(mets_directory_scan_job.default_priority).to eq(70)
  end

  it "has correct queue" do
    expect(mets_directory_scan_job.queue_name).to eq('default')
  end

  it "is scheduled to run nightly at 7:00 pm ET (23:00 UTC)" do
    entry = GoodJob::CronEntry.all.find { |e| e.key == :mets_directory_scan }
    expect(entry.instance_variable_get(:@params)).to eq({ cron: "0 23 * * *", class: "MetsDirectoryScanJob", key: :mets_directory_scan })
  end
end
