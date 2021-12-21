# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ExportAdminSetCsvJob, type: :job do
  def queue_adapter_for_test
    ActiveJob::QueueAdapters::DelayedJobAdapter.new
  end

  let(:user) { FactoryBot.create(:user) }
  let(:batch_process) { FactoryBot.create(:batch_process, user: user) }
  let(:export_admin_set_csv_job) { ExportAdminSetCsvJob.new }
  let(:brbl) { AdminSet.find_by_key("brbl") }
  let(:other_admin_set) { FactoryBot.create(:admin_set) }
  let(:parent_object) { FactoryBot.create(:parent_object, oid: 2_034_600, admin_set: brbl) }

  it 'increments the job queue by one' do
    ActiveJob::Base.queue_adapter = :delayed_job
    expect do
      described_class.perform_later(batch_process, brbl)
    end.to change { Delayed::Job.count }.by(1)
  end

  it "has correct priority" do
    expect(export_admin_set_csv_job.default_priority).to eq(-100)
  end

  it "has correct queue" do
    expect(export_admin_set_csv_job.queue_name).to eq('default')
  end

  it 'calls parent_output_csv when performed' do
    expect(batch_process).to receive(:export_admin_set_csv).once
    described_class.new.perform(batch_process, brbl)
  end

  it 'reports error when parent_output_csv fails' do
    allow(batch_process).to receive(:export_admin_set_csv).and_raise('boom!')
    inst = described_class.new
    expect do
      inst.perform(batch_process, brbl)
    end.to raise_error('boom!')
  end
end
