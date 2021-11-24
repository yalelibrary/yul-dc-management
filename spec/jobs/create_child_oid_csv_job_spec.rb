# frozen_string_literal: true
require 'rails_helper'

RSpec.describe CreateChildOidCsvJob, type: :job do
  def queue_adapter_for_test
    ActiveJob::QueueAdapters::DelayedJobAdapter.new
  end

  let(:user) { FactoryBot.create(:user) }
  let(:batch_process) { FactoryBot.create(:batch_process, user: user) }

  it 'increments the job queue by one' do
    ActiveJob::Base.queue_adapter = :delayed_job
    expect do
      described_class.perform_later(batch_process)
    end.to change { Delayed::Job.count }.by(1)
  end

  it 'calls output_csv when performed' do
    expect(batch_process).to receive(:output_csv).once
    described_class.new.perform(batch_process)
  end

  it 'reports error when output_csv fails' do
    allow(batch_process).to receive(:output_csv).and_raise('boom!')
    inst = described_class.new
    expect do
      inst.perform(batch_process)
    end.to raise_error('boom!')
  end
end
