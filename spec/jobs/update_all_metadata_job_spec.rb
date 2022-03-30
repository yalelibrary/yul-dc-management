# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UpdateAllMetadataJob, type: :job, prep_metadata_sources: true, solr: true do
  let(:parent_object) { FactoryBot.build(:parent_object, oid: '16797069') }

  context 'with tests active job queue' do
    def queue_adapter_for_test
      ActiveJob::QueueAdapters::DelayedJobAdapter.new
    end

    it 'increments the job queue by one' do
      parent_object
      ActiveJob::Base.queue_adapter = :delayed_job
      expect do
        UpdateAllMetadataJob.perform_later
      end.to change { Delayed::Job.count }.by(1)
    end
  end

  context 'with more than limit parent objects' do
    let(:parent_object_where) { double }
    let(:total_records) { 8000 }
    let(:limit) { UpdateAllMetadataJob.job_limit }
    let(:expected_call_count) { (total_records.to_f / limit).ceil }

    before do
      # create mocks
      parent = double
      expect(parent).to receive(:metadata_update=).exactly(total_records).times
      expect(parent).to receive(:setup_metadata_job).exactly(total_records).times

      parent_object_order = double
      parent_object_order_offset1 = double
      parent_object_order_offset2 = double
      expect(parent_object_where).to receive(:order).and_return(parent_object_order).exactly(expected_call_count).times
      expect(parent_object_order).to receive(:offset).with(0).and_return parent_object_order_offset1
      expect(parent_object_order).to receive(:offset).with(limit).and_return parent_object_order_offset2
      expect(parent_object_order_offset1).to receive(:limit).with(limit).and_return [*1..limit].map { |_ix| parent }
      expect(parent_object_order_offset2).to receive(:limit).with(limit).and_return [*1..(total_records - limit)].map { |_ix| parent }
    end

    around do |example|
      perform_enqueued_jobs do
        example.run
      end
    end

    it 'processes all parents in batches' do
      expect(ParentObject).to receive(:where).with('redirect_to: nil').and_return(parent_object_where).exactly(expected_call_count).times
      UpdateAllMetadataJob.perform_later
    end

    it 'processes parents with where' do
      where = { admin_set_id: [1, 2, 3], authoritative_metadata_source_id: [2, 3], redirect_to: nil }
      expect(ParentObject).to receive(:where).with(where).and_return(parent_object_where).exactly(expected_call_count).times
      UpdateAllMetadataJob.perform_later(0, admin_set_id: [1, 2, 3], authoritative_metadata_source_id: [2, 3], redirect_to: nil)
    end
  end
end
