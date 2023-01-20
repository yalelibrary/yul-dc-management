# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UpdateManifestsJob, type: :job, prep_metadata_sources: true, solr: true do
  let(:parent_object) { FactoryBot.build(:parent_object, oid: '16797069') }
  let(:user) { FactoryBot.create(:user) }
  let(:batch_process) { FactoryBot.create(:batch_process, user: user, batch_action: 'update parent objects') }
  let(:admin_set_1) { FactoryBot.create(:admin_set) }

  before do
    admin_set_1.add_editor(user)
  end

  context 'with tests active job queue' do
    def queue_adapter_for_test
      ActiveJob::QueueAdapters::DelayedJobAdapter.new
    end

    it 'increments the job queue by one' do
      ActiveJob::Base.queue_adapter = :delayed_job
      expect do
        UpdateManifestsJob.perform_later
      end.to change { Delayed::Job.count }.by(1)
    end
  end

  context 'with more than limit parent objects' do
    let(:po1) { FactoryBot.build(:parent_object, oid: '000000001', admin_set_id: admin_set_1.id) }
    let(:po2) { FactoryBot.build(:parent_object, oid: '000000002', admin_set_id: admin_set_1.id) }
    let(:po3) { FactoryBot.build(:parent_object, oid: '000000003', admin_set_id: admin_set_1.id) }
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
      UpdateManifestsJob.perform_later(0, 1, batch_process)
    end
  end
end
