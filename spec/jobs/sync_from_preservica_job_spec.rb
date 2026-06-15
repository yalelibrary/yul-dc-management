# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SyncFromPreservicaJob, type: :job, prep_metadata_sources: true, prep_admin_sets: true do
  include ActiveSupport::Testing::TaggedLogging

  def with_good_job_external_mode
    original_queue_adapter = described_class.queue_adapter
    described_class.queue_adapter = GoodJob::Adapter.new(execution_mode: :external)
    yield
  ensure
    described_class.queue_adapter = original_queue_adapter
  end

  def run_sync_from_preservica_retry_jobs
    GoodJob.perform_inline
    3.times do
      scheduled_jobs = GoodJob::Job.where(job_class: 'SyncFromPreservicaJob')
                                   .where(finished_at: nil)
                                   .where("scheduled_at > ?", Time.current)
      break if scheduled_jobs.none?

      scheduled_jobs.find_each { |job| job.update!(scheduled_at: Time.current) }
      GoodJob.perform_inline
    end
  end

  let(:user) { FactoryBot.create(:user) }
  let(:batch_process) { FactoryBot.create(:batch_process, user: user) }

  it 'increments the job queue by one' do
    resync_preservica_job = described_class.perform_later(batch_process)
    expect(resync_preservica_job.instance_variable_get(:@successfully_enqueued)).to eq true
  end

  it "has correct priority" do
    sync_from_preservica_job = described_class.new
    expect(sync_from_preservica_job.default_priority).to eq(50)
  end

  it 'is configured to retry on errors' do
    # Verify the job class has retry configuration by inspecting the class directly
    expect(described_class.ancestors).to include(ActiveJob::Exceptions::ClassMethods)

    # Verify retry configuration in the job code
    job_file = File.read(Rails.root.join('app', 'jobs', 'sync_from_preservica_job.rb'))
    expect(job_file).to include('retry_on RuntimeError')
    expect(job_file).to include('Net::ReadTimeout')
    expect(job_file).to include('attempts: 3')
  end

  it 'logs failed batch processing event on first retryable failure' do
    allow(batch_process).to receive(:sync_from_preservica).and_raise(StandardError.new('Something went wrong'))
    allow(batch_process).to receive(:batch_processing_event)

    expect do
      described_class.perform_now(batch_process)
    end.not_to raise_error

    expect(batch_process).to have_received(:batch_processing_event)
      .with('Setup job failed to save: Something went wrong', 'failed')
  end

  it 'logs retry batch processing event when retries are exhausted' do
    with_good_job_external_mode do
      GoodJob::Job.where(job_class: 'SyncFromPreservicaJob').delete_all
      allow_any_instance_of(BatchProcess).to receive(:sync_from_preservica).and_raise(StandardError.new('Something went wrong'))
      allow(BatchProcess).to receive(:find_by).with(id: batch_process.id).and_return(batch_process)

      described_class.perform_later(batch_process)
      run_sync_from_preservica_retry_jobs

      reasons = batch_process.batch_ingest_events.where(status: 'retry').pluck(:reason)
      expect(reasons).to include('Retrying Sync from Preservica - Request error Something went wrong')
    end
  end

  context 'when sync_from_preservica raises an exception' do
    let(:error_message) { 'Something went wrong' }
    let(:error) { StandardError.new(error_message) }

    before do
      allow(batch_process).to receive(:sync_from_preservica).and_raise(error)
      allow(batch_process).to receive(:batch_processing_event)
    end

    it 'logs the error with batch_processing_event' do
      expect(batch_process).to receive(:batch_processing_event)
        .with("Setup job failed to save: #{error_message}", "failed")

      # this bypasses ActiveJob's retry mechanism by using perform instead of perform_later
      expect do
        described_class.new.perform(batch_process)
      end.to raise_error(StandardError, error_message)
    end
  end
end
