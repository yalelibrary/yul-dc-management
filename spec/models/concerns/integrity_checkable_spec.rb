# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IntegrityCheckable, type: :model, prep_metadata_sources: true, prep_admin_sets: true do
  let(:metadata_source) { MetadataSource.first }
  let(:admin_set) { AdminSet.first }
  let(:parent_object) { FactoryBot.create(:parent_object, oid: '222', authoritative_metadata_source: metadata_source, admin_set: admin_set) }
  let(:child_object_one) { FactoryBot.create(:child_object, oid: '1', parent_object: parent_object) }
  let(:child_object_two) { FactoryBot.create(:child_object, oid: '2', parent_object: parent_object) }
  let(:child_object_three) { FactoryBot.create(:child_object, oid: '3', parent_object: parent_object) }
    
  before do
    allow(GoodJob).to receive(:preserve_job_records).and_return(true)
    ActiveJob::Base.queue_adapter = GoodJob::Adapter.new(execution_mode: :inline)
    parent_object
    # set up fixtures for child objects
    # file not present
    # file present but checksum does not match
    # file present and checksum matches
  end

  it 'reflects messages as expected' do
    expect { ChildObjectIntegrityCheckJob.new.perform }.to change { IngestEvent.count }.by(1)
    # when checksum does not match and file is present
    # on batch process child object detail page
    # gives failure message xxxxxx

    # when file is not present
    # on batch process child object detail page
    # gives failure message xxxxxx and message yyyyyyy

    # when checksum matches and file is present
    # on batch process child object detail page
    # gives success /complete
  end

  # set up 2500 child objects
  # make sure only grabs 2000



  # make sure it does not sample preservica parents

  # let(:reassociatable) { BatchProcess.new }
  # let(:metadata_source) { MetadataSource.first }
  # let(:parent_object) { FactoryBot.create(:parent_object, oid: '222', authoritative_metadata_source: metadata_source) }
  # let(:child_object) { FactoryBot.create(:child_object, oid: '1', label: 'original label',
  # caption: 'original caption', viewing_hint: 'original viewing hint', order: 5, parent_object: parent_object) }

  # context 'with more than limit parent objects' do
  #   before do
  #     limit = SolrReindexAllJob.job_limit
  #     solr_limit = SolrReindexAllJob.solr_batch_limit
  #     total_records = 8000 #  some number > SolrReindexAllJob.job_limit < SolrReindexAllJob.job_limit * 2

  #     # create mocks for everything the job uses
  #     solr_service = double
  #     expect(SolrService).to receive(:connection).and_return(solr_service).twice
  #     expect(SolrService).to receive(:clean_index_orphans).once

  #     # 2 * because of the children
  #     expect(solr_service).to receive(:add).exactly(2 * total_records / solr_limit).times
  #     expect(solr_service).to receive(:commit).exactly(2 * total_records / solr_limit).times

  #     doc = double
  #     expect(doc).to receive(:to_solr_full_text).and_return([nil, [double]]).exactly(total_records).times

  #     parent_object_order = double
  #     parent_object_order_offset1 = double
  #     parent_object_order_offset2 = double
  #     expect(ParentObject).to receive(:order).and_return(parent_object_order).exactly((total_records.to_f / limit).ceil).times
  #     expect(parent_object_order).to receive(:offset).with(0).and_return parent_object_order_offset1
  #     expect(parent_object_order).to receive(:offset).with(limit).and_return parent_object_order_offset2
  #     expect(parent_object_order_offset1).to receive(:limit).with(limit).and_return [*1..limit].map { |_ix| doc }
  #     expect(parent_object_order_offset2).to receive(:limit).with(limit).and_return [*1..(total_records - limit)].map { |_ix| doc }
  #   end

  #   around do |example|
  #     perform_enqueued_jobs do
  #       example.run
  #     end
  #   end

  #   it 'goes through all parents in batches' do
  #     SolrReindexAllJob.perform_later
  #   end
  # end
end
