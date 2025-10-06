# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SyncFromPreservicaJob, type: :job, prep_metadata_sources: true, prep_admin_sets: true do
  include ActiveSupport::Testing::TaggedLogging
  before do
    allow(GoodJob).to receive(:preserve_job_records).and_return(true)
    ActiveJob::Base.queue_adapter = GoodJob::Adapter.new(execution_mode: :external)
  end

  let(:user) { FactoryBot.create(:user) }
  let(:batch_process) { FactoryBot.create(:batch_process, user: user) }

  it 'increments the job queue by one' do
    resync_preservica_job = described_class.perform_later(batch_process)
    expect(resync_preservica_job.instance_variable_get(:@successfully_enqueued)).to eq true
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

  it 'handles error' do
    allow_any_instance_of(SyncFromPreservicaJob).to receive(:perform).and_raise(RuntimeError.new(nil))
    expect_any_instance_of(SyncFromPreservicaJob).to receive(:retry_job)
    perform_enqueued_jobs do
      SyncFromPreservicaJob.perform_later(batch_process)
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

      expect do
        described_class.new.perform(batch_process)
      end.not_to raise_error
    end
  end
end
