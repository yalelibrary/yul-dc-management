# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CreatePreservicaChildrenJob, type: :job, prep_admin_sets: true, prep_metadata_sources: true do
  before do
    allow(GoodJob).to receive(:preserve_job_records).and_return(true)
    ActiveJob::Base.queue_adapter = GoodJob::Adapter.new(execution_mode: :inline)
  end

  let(:user) { FactoryBot.create(:user) }
  let(:batch_process) { FactoryBot.create(:batch_process, user: user) }
  let(:parent_object) do
    FactoryBot.create(:parent_object,
                      oid: 2_034_600,
                      admin_set: AdminSet.first,
                      authoritative_metadata_source: MetadataSource.first,
                      digital_object_source: "Preservica",
                      preservica_uri: "/structural-objects/test-uuid",
                      preservica_representation_type: "Access")
  end
  let(:job) { described_class.new }

  it 'enqueues the job successfully' do
    active_job = described_class.perform_later(parent_object, batch_process)
    expect(active_job.instance_variable_get(:@successfully_enqueued)).to be true
  end

  it 'uses the default queue' do
    expect(described_class.new.queue_name).to eq('default')
  end

  context 'when performing' do
    before do
      allow(parent_object).to receive(:create_child_records)
      allow(parent_object).to receive(:save!)
      allow(parent_object).to receive(:reload)
      allow(parent_object).to receive(:gather_technical_image_metadata)
      allow(parent_object).to receive(:processing_event)
      allow(parent_object).to receive(:child_objects).and_return([])
      allow(parent_object).to receive(:needs_a_manifest?).and_return(false)
    end

    it 'calls create_child_records on the parent object' do
      job.perform(parent_object, batch_process)
      expect(parent_object).to have_received(:create_child_records)
    end

    it 'saves and reloads the parent object' do
      job.perform(parent_object, batch_process)
      expect(parent_object).to have_received(:save!)
      expect(parent_object).to have_received(:reload)
    end

    it 'gathers technical image metadata' do
      job.perform(parent_object, batch_process)
      expect(parent_object).to have_received(:gather_technical_image_metadata)
    end

    it 'logs a child-records-created event' do
      job.perform(parent_object, batch_process)
      expect(parent_object).to have_received(:processing_event).with("Child object records have been created", "child-records-created")
    end
  end
end
