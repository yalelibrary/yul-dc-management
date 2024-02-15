# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ExportAllParentSourcesCsvJob, type: :job do
  def queue_adapter_for_test
    ActiveJob::QueueAdapters::DelayedJobAdapter.new
  end

  let(:user) { FactoryBot.create(:user) }
  let(:batch_process) { FactoryBot.create(:batch_process, user: user) }
  let(:export_all_parent_sources_csv_job) { ExportAllParentSourcesCsvJob.new }

  it 'increments the job queue by one' do
    ActiveJob::Base.queue_adapter = :delayed_job
    expect do
      described_class.perform_later(batch_process)
    end.to change { Delayed::Job.count }.by(1)
  end

  it "has correct priority" do
    expect(export_all_parent_sources_csv_job.default_priority).to eq(-100)
  end

  it "has correct queue" do
    expect(export_all_parent_sources_csv_job.queue_name).to eq('default')
  end

  it 'calls export_all_parents_source_csv when performed' do
    expect(batch_process).to receive(:export_all_parents_source_csv).once
    described_class.new.perform(batch_process, ["1"])
  end

  it 'reports error when export_all_parents_source_csv fails' do
    allow(batch_process).to receive(:export_all_parents_source_csv).and_raise('boom!')
    inst = described_class.new
    expect do
      inst.perform(batch_process, ["1"])
    end.to raise_error('boom!')
  end
end
