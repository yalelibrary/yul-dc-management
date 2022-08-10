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
    let(:parent_object) { FactoryBot.create(:parent_object, authoritative_metadata_source: metadata_source) }

    it 'notifies on save failure' do
      allow(parent_object).to receive(:default_fetch).and_raise('boom!')
      expect(parent_object).to receive(:processing_event).once
      expect { metadata_job.perform(parent_object, batch_process) }.to raise_error('boom!')
    end

    it 'notifies if all images are not present' do
      # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(SetupMetadataJob).to receive(:check_mets_images).and_return(false)
      # rubocop:enable RSpec/AnyInstance
      expect(parent_object).to receive(:processing_event).with("SetupMetadataJob failed to find all images.", "failed").once
      metadata_job.perform(parent_object, batch_process)
    end
  end
end
