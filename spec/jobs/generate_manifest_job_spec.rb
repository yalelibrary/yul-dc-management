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

    context 'job failes' do
      let(:metadata_source) { FactoryBot.create(:metadata_source) }
      let(:parent_object) { FactoryBot.create(:parent_object, authoritative_metadata_source: metadata_source) }
      before do
        allow(parent_object).to receive(:solr_index).and_raise('boom!')
      end

      it 'notifies on Solr index failure' do
        expect(parent_object).to receive(:processing_failure)
        expect { generate_manifest_job.perform(parent_object) }.to raise_error('boom!')
      end
    end
  end
end
