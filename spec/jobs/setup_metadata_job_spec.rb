# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SetupMetadataJob, type: :job do
  def queue_adapter_for_test
    ActiveJob::QueueAdapters::DelayedJobAdapter.new
  end

  let(:metadata_job) { SetupMetadataJob.new }

  it 'increments the job queue by one' do
    ActiveJob::Base.queue_adapter = :delayed_job
    expect do
      SetupMetadataJob.perform_later(metadata_job)
    end.to change { Delayed::Job.count }.by(1)
  end
end
