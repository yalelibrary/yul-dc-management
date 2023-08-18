# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SetupMetadataJob, type: :job, prep_admin_sets: true, prep_metadata_sources: true do
  before do
    allow(GoodJob).to receive(:preserve_job_records).and_return(true)
    ActiveJob::Base.queue_adapter = GoodJob::Adapter.new(execution_mode: :inline)
  end

  let(:metadata_job) { SetupMetadataJob.new }

  it 'completes successfully' do
    active_job = described_class.perform_later(metadata_job)
    10.times do
      GoodJob.perform_inline
      travel(5.minutes)
    end
    good_job = GoodJob::Job.find_by(active_job_id: active_job.job_id)
    expect(good_job.discrete_executions.count).to eq 1
    expect(good_job.discrete_executions.last.error).to be_nil
  end

  it 'increments the job queue by one' do
    expect do
      SetupMetadataJob.perform_later(metadata_job)
    end.to change { GoodJob::Job.count }.by(1)
  end

  context 'job fails' do
    let(:user) { FactoryBot.create(:user) }
    let(:batch_process) { FactoryBot.create(:batch_process, user: user) }
    let(:parent_object) { FactoryBot.create(:parent_object, admin_set: AdminSet.first, authoritative_metadata_source: MetadataSource.first) }

    it 'notifies on save failure' do
      allow(parent_object).to receive(:default_fetch).and_raise('boom!')
      expect(parent_object).to receive(:processing_event).twice
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
