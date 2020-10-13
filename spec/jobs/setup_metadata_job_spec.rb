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

  context 'job fails' do
    let(:user) { FactoryBot.create(:user) }
    let(:batch_process) { FactoryBot.create(:batch_process, user: user) }
    let(:metadata_source) { FactoryBot.create(:metadata_source) }
    let(:parent_object) { FactoryBot.build(:parent_object, authoritative_metadata_source: metadata_source) }
    before do
      allow(parent_object).to receive(:save!).and_raise('boom!')
    end

    it 'notifies on save failure' do
      expect(parent_object).to receive(:processing_event).twice
      expect { metadata_job.perform(parent_object, batch_process) }.to raise_error('boom!')
    end
  end
end
