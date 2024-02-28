# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UpdateManifestsJob, type: :job, prep_metadata_sources: true, prep_admin_sets: true, solr: true do
  let(:parent_object) { FactoryBot.build(:parent_object, oid: '16797069') }
  let(:user) { FactoryBot.create(:user) }
  let(:admin_set_1) { AdminSet.first }

  before do
    admin_set_1.add_editor(user)
  end

  context 'with tests active job queue' do
    before do
      allow(GoodJob).to receive(:preserve_job_records).and_return(true)
      ActiveJob::Base.queue_adapter = GoodJob::Adapter.new(execution_mode: :inline)
    end

    it 'increments the job queue by one' do
      manifests_job = described_class.perform_later
      expect(manifests_job.instance_variable_get(:@successfully_enqueued)).to eq true
    end
  end

  context 'with more than limit parent objects' do
    let(:po1) { FactoryBot.create(:parent_object, oid: '000000001', admin_set_id: admin_set_1.id, authoritative_metadata_source: MetadataSource.first) }
    let(:po2) { FactoryBot.create(:parent_object, oid: '000000002', admin_set_id: admin_set_1.id, authoritative_metadata_source: MetadataSource.first) }
    let(:po3) { FactoryBot.create(:parent_object, oid: '000000003', admin_set_id: admin_set_1.id, authoritative_metadata_source: MetadataSource.first) }
    let(:total_records) { 3 }
    let(:limit) { UpdateManifestsJob.job_limit }
    let(:expected_call_count) { (total_records.to_f / limit).ceil }

    before do
      po1
      po2
      po3
      UpdateManifestsJob.job_limit { 2 }
    end

    around do |example|
      perform_enqueued_jobs do
        example.run
      end
    end

    it 'processes all parents in batches' do
      expect(UpdateManifestsJob).to receive(:perform_later).exactly(expected_call_count).times
      UpdateManifestsJob.perform_later(admin_set_1.id)
    end
  end
end
