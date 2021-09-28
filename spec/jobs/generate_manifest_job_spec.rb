# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GenerateManifestJob, type: :job do
  def queue_adapter_for_test
    ActiveJob::QueueAdapters::DelayedJobAdapter.new
  end

  let(:parent_object) { FactoryBot.build(:parent_object, oid: '16797069') }
  let(:generate_manifest_job) { GenerateManifestJob.new }

  describe 'generate manifests job' do
    it 'increments the job queue by one' do
      expect do
        GenerateManifestJob.perform_later(parent_object)
      end.to change { Delayed::Job.count }.by(1)
    end

    context 'job fails' do
      let(:user) { FactoryBot.create(:user) }
      let(:metadata_source) { FactoryBot.create(:metadata_source) }
      let(:parent_object) { FactoryBot.create(:parent_object, authoritative_metadata_source: metadata_source) }
      let(:batch_process) { FactoryBot.create(:batch_process, user: user) }

      it 'notifies on Solr index failure' do
        allow(parent_object).to receive(:solr_index_job).and_raise('boom!')
        expect(parent_object).to receive(:processing_event).twice
        expect { generate_manifest_job.perform(parent_object, batch_process) }.to raise_error('boom!')
      end

      it 'notifies when save fails' do
        allow(parent_object.iiif_presentation).to receive(:save).and_return(false)
        expect(parent_object).to receive(:processing_event).with("IIIF Manifest not saved to S3", "failed")
        generate_manifest_job.perform(parent_object, batch_process)
      end

      it 'notifies when save raises error' do
        allow(parent_object.iiif_presentation).to receive(:save).and_raise('boom!')
        expect(parent_object).to receive(:processing_event)
        expect { generate_manifest_job.perform(parent_object, batch_process) }.to raise_error('boom!')
      end
    end
  end
end
