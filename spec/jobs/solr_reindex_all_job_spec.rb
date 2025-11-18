# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SolrReindexAllJob, type: :job, prep_metadata_sources: true, solr: true do
  context 'with tests active job queue' do
    before do
      allow(GoodJob).to receive(:preserve_job_records).and_return(true)
      ActiveJob::Base.queue_adapter = GoodJob::Adapter.new(execution_mode: :inline)
    end

    it 'increments the job queue by one' do
      solr_reindex_job = described_class.perform_later
      expect(solr_reindex_job.instance_variable_get(:@successfully_enqueued)).to be true
    end

    context 'with Private visibility, well formed json and child objects' do
      before do
        stub_metadata_cloud('AS-781086', 'aspace')
      end
      it 'can succeed and notify user but does not index Private object' do
        private_parent_object_with_well_formed_json = FactoryBot.create(:parent_object, oid: 781_086)
        private_parent_object_with_well_formed_json.save!
        child_object = FactoryBot.create(:child_object, parent_object: private_parent_object_with_well_formed_json)
        child_object.save!
        private_parent_object_with_well_formed_json.reload
        solr_service = double
        expect(SolrService).to receive(:connection).and_return(solr_service)
        expect(SolrService).to receive(:clean_index_orphans).once
        expect(solr_service).to receive(:add).with([])
        expect(solr_service).to receive(:commit)
        solr_reindex_job = described_class.perform_later
        expect(solr_reindex_job.instance_variable_get(:@successfully_enqueued)).to be true
        solr_reindex_job.perform
        expect(IngestEvent.all.first.reason).to eq 'SolrReindexAllJob successfully completed evaluating 1 parent objects for indexing.'
      end
    end
    context 'with Public visibility, well formed json and child objects' do
      before do
        stub_metadata_cloud('AS-2005512', 'aspace')
      end
      it 'can succeed and notify user and index parent object' do
        public_parent_object_with_well_formed_json = FactoryBot.create(:parent_object,
          oid: 2_005_512,
          visibility: 'Public',
          aspace_json: JSON.parse(File.read(File.join(fixture_path, "aspace", "AS-2005512.json"))),
          authoritative_metadata_source_id: 3)
        allow_any_instance_of(ParentObject).to receive(:manifest_completed?).and_return(true)
        public_parent_object_with_well_formed_json.save!
        child_object = FactoryBot.create(:child_object, parent_object: public_parent_object_with_well_formed_json, oid: 1_489_345)
        child_object.save!
        public_parent_object_with_well_formed_json.reload
        solr_service = double
        expect(SolrService).to receive(:connection).and_return(solr_service)
        expect(SolrService).to receive(:clean_index_orphans).once
        expect(solr_service).to receive(:add).with([public_parent_object_with_well_formed_json.to_solr_full_text.first])
        expect(solr_service).to receive(:add).with([{ caption_tesim: "MyString", caption_wstsim: "MyString", id: 1_489_345, parent_ssi: 2_005_512, type_ssi: "child" }])
        expect(solr_service).to receive(:commit).twice
        solr_reindex_job = described_class.perform_later
        expect(solr_reindex_job.instance_variable_get(:@successfully_enqueued)).to be true
        solr_reindex_job.perform
        expect(IngestEvent.all.first.reason).to eq 'SolrReindexAllJob successfully completed evaluating 1 parent objects for indexing.'
      end
    end
    context 'with malformed json' do
      before do
        stub_metadata_cloud('AS-781087', 'aspace')
      end
      it 'can fail and notify user' do
        parent_object_with_malformed_json = FactoryBot.create(:parent_object,
          oid: 781_087,
          visibility: 'Public',
          aspace_json: File.read(File.join(fixture_path, "aspace", "AS-781087.json")),
          authoritative_metadata_source_id: 3)
        allow_any_instance_of(ParentObject).to receive(:manifest_completed?).and_return(true)
        parent_object_with_malformed_json.save!
        child_object = FactoryBot.create(:child_object, parent_object: parent_object_with_malformed_json, oid: 13_523_416)
        child_object.save!
        parent_object_with_malformed_json.reload
        solr_service = double
        expect(SolrService).to receive(:connection).and_return(solr_service)
        expect(SolrService).not_to receive(:clean_index_orphans)
        expect(solr_service).not_to receive(:add)
        expect(solr_service).not_to receive(:commit)
        solr_reindex_job = described_class.perform_later
        expect(solr_reindex_job.instance_variable_get(:@successfully_enqueued)).to be true
        solr_reindex_job.perform
        expect(IngestEvent.all.first.reason).to eq "SolrReindexAllJob failed due to no implicit conversion of String into Array for parent object OID: #{parent_object_with_malformed_json.oid}."
      end
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

      expect(solr_service).to receive(:add).exactly(total_records / solr_limit).times
      expect(solr_service).to receive(:commit).exactly(total_records / solr_limit).times

      doc = double
      expect(doc).to receive(:should_index?).and_return(true).exactly(total_records).times
      expect(doc).to receive(:to_solr_full_text).and_return(double).exactly(total_records).times

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
