# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AddExtentOfDigitizationToParentObjectsJob, type: :job do
  def queue_adapter_for_test
    ActiveJob::QueueAdapters::DelayedJobAdapter.new
  end

  let(:user) { FactoryBot.create(:user) }
  let(:batch_process) { FactoryBot.create(:batch_process, user: user) }
  let(:add_extent_job) { AddExtentOfDigitizationToParentObjectsJob.new }

  it 'increments the job queue by one' do
    ActiveJob::Base.queue_adapter = :delayed_job
    expect do
      described_class.perform_later(batch_process)
    end.to change { Delayed::Job.count }.by(1)
  end

  it "has correct priority" do
    expect(add_extent_job.default_priority).to eq(-100)
  end

  it "has correct queue" do
    expect(add_extent_job.queue_name).to eq('default')
  end
end
