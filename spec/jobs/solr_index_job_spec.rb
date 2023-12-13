# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SolrIndexJob, type: :job, prep_metadata_sources: true, prep_admin_sets: true do
  before do
    allow(GoodJob).to receive(:preserve_job_records).and_return(true)
    ActiveJob::Base.queue_adapter = GoodJob::Adapter.new(execution_mode: :inline)
  end

  let(:parent_object) { FactoryBot.build(:parent_object, oid: '16797069', authoritative_metadata_source: MetadataSource.first, admin_set: AdminSet.first) }

  it 'increments the job queue' do
    solr_job = described_class.perform_later(parent_object)
    expect(solr_job.instance_variable_get(:@successfully_enqueued)).to be true
  end

  it 'increments the job queue by just one with multiple calls to solr_index_job' do
    expect(SolrIndexJob).to receive(:perform_later).once
    parent_object.solr_index_job
    allow(parent_object).to receive(:queued_solr_index_jobs).and_return('sample existing solr index job')
    parent_object.solr_index_job
    parent_object.solr_index_job
    parent_object.solr_index_job
  end

  it 'increments the solr_index job queue when not full text' do
    allow(parent_object).to receive(:full_text?).and_return(false)
    solr_job = parent_object.solr_index_job
    expect(solr_job.instance_variable_get(:@queue_name)).to eq 'solr_index'
  end

  it 'does not increment the solr_index job queue when full text' do
    allow(parent_object).to receive(:full_text?).and_return(true)
    solr_job = parent_object.solr_index_job
    expect(solr_job.instance_variable_get(:@queue_name)).not_to eq 'solr_index'
  end

  it 'does not increment the intensive_solr_index job queue when not full text' do
    allow(parent_object).to receive(:full_text?).and_return(false)
    solr_job = parent_object.solr_index_job
    expect(solr_job.instance_variable_get(:@queue_name)).not_to eq 'intensive_solr_index'
  end

  it 'increments the intensive_solr_index job queue when full text' do
    allow(parent_object).to receive(:full_text?).and_return(true)
    solr_job = parent_object.solr_index_job
    expect(solr_job.instance_variable_get(:@queue_name)).to eq 'intensive_solr_index'
  end
end
