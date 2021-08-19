# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SolrReindexAllJob, type: :job, prep_metadata_sources: true, solr: true do
  context 'with tests active job queue' do
    def queue_adapter_for_test
      ActiveJob::QueueAdapters::DelayedJobAdapter.new
    end

    it 'increments the job queue by one' do
      ActiveJob::Base.queue_adapter = :delayed_job
      expect do
        SolrReindexAllJob.perform_later
      end.to change { Delayed::Job.count }.by(1)
    end
  end

  context 'with more than limit parent objects' do
    before do
      limit = SolrReindexAllJob.job_limit
      solr_limit = SolrReindexAllJob.solr_batch_limit
      total_records = 8000 #  some number > SolrReindexAllJob.job_limit < SolrReindexAllJob.job_limit * 2

      # create mocks for everything the job uses
      solr_service = double
      expect(SolrService).to receive(:connection).and_return(solr_service).twice
      expect(SolrService).to receive(:clean_index_orphans).once

      # 2 * because of the children
      expect(solr_service).to receive(:add).exactly(2 * total_records / solr_limit).times
      expect(solr_service).to receive(:commit).exactly(2 * total_records / solr_limit).times

      doc = double
      expect(doc).to receive(:to_solr_full_text).and_return([nil, [double]]).exactly(total_records).times

      parent_object_order = double
      parent_object_order_offset1 = double
      parent_object_order_offset2 = double
      expect(ParentObject).to receive(:order).and_return(parent_object_order).exactly((total_records.to_f / limit).ceil).times
      expect(parent_object_order).to receive(:offset).with(0).and_return parent_object_order_offset1
      expect(parent_object_order).to receive(:offset).with(limit).and_return parent_object_order_offset2
      expect(parent_object_order_offset1).to receive(:limit).with(limit).and_return [*1..limit].map { |_ix| doc }
      expect(parent_object_order_offset2).to receive(:limit).with(limit).and_return [*1..(total_records - limit)].map { |_ix| doc }
    end

    around do |example|
      perform_enqueued_jobs do
        example.run
      end
    end

    it 'goes through all parents in batches' do
      SolrReindexAllJob.perform_later
    end
  end
end
