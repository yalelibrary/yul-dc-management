# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GenerateManifestJob, type: :job, prep_admin_sets: true, prep_metadata_sources: true do
  let(:user) { FactoryBot.create(:user) }
  let(:batch_process) { FactoryBot.create(:batch_process, user: user) }
  let(:parent_object) { FactoryBot.create(:parent_object, oid: '2005512', authoritative_metadata_source: MetadataSource.first, admin_set: AdminSet.first) }
  let(:generate_manifest_job) { GenerateManifestJob.new }

  before do
    allow_any_instance_of(MetadataSource).to receive(:fetch_record).and_return(File.read(fixture_paths[0] + "/ladybird/2005512.json"))
    allow_any_instance_of(ParentObject).to receive(:authoritative_json).and_return(JSON.parse(File.read(fixture_paths[0] + "/ladybird/2005512.json")))
  end

  describe 'generate manifests job' do
    it 'increments the job queue' do
      parent_object.save!
      generate_manifest_job = described_class.perform_later(parent_object, batch_process)
      expect(generate_manifest_job.instance_variable_get(:@successfully_enqueued)).to be true
    end

    context 'job fails' do
      let(:parent_object) { FactoryBot.create(:parent_object, authoritative_metadata_source: MetadataSource.first, admin_set: AdminSet.first) }
      let(:child_object) { FactoryBot.create(:child_object, oid: '456789', parent_object: parent_object) }

      it 'notifies on Solr index failure' do
        allow(parent_object).to receive(:solr_index_job).and_raise('boom!')
        expect(parent_object).to receive(:processing_event)
        expect { generate_manifest_job.perform(parent_object, batch_process) }.to raise_error('boom!')
      end

      it 'notifies when save fails' do
        allow(parent_object.iiif_presentation).to receive(:save).and_return(false)
        expect(parent_object).to receive(:processing_event).with('IIIF Manifest not saved to S3', 'failed')
        generate_manifest_job.perform(parent_object, batch_process)
      end

      it 'notifies when save raises error' do
        allow(parent_object.iiif_presentation).to receive(:save).and_raise('boom!')
        expect(parent_object).to receive(:processing_event)
        expect { generate_manifest_job.perform(parent_object, batch_process) }.to raise_error('boom!')
      end

      it 'does not raise error when child does not have dimensions' do
        child_object.width = nil
        child_object.height = nil
        child_object.save
        expect { generate_manifest_job.perform(parent_object, batch_process) }.not_to raise_error
      end
    end
  end
end
