# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SolrIndexJob, type: :job do
  let(:parent_object) { FactoryBot.build(:parent_object, oid: '16797069') }

  it 'increments the job queue by one' do
    expect do
      SolrIndexJob.perform_later(parent_object)
    end.to change { GoodJob::Job.count }.by(1)
  end

  it 'increments the job queue by just one with multiple calls to solr_index_job' do
    expect do
      parent_object.solr_index_job
      parent_object.solr_index_job
      parent_object.solr_index_job
    end.to change { GoodJob::Job.count }.by(1)
  end

  it 'increments the solr_index job queue when not full text' do
    expect do
      allow(parent_object).to receive(:full_text?).and_return(false)
      parent_object.solr_index_job
    end.to change { GoodJob::Job.where(queue: 'solr_index').count }.by(1)
  end

  it 'does not increment the solr_index job queue when full text' do
    expect do
      allow(parent_object).to receive(:full_text?).and_return(true)
      parent_object.solr_index_job
    end.to change { GoodJob::Job.where(queue: 'solr_index').count }.by(0)
  end

  it 'does not increment the intensive_solr_index job queue when not full text' do
    expect do
      allow(parent_object).to receive(:full_text?).and_return(false)
      parent_object.solr_index_job
    end.to change { GoodJob::Job.where(queue: 'intensive_solr_index').count }.by(0)
  end

  it 'increments the intensive_solr_index job queue when full text' do
    expect do
      allow(parent_object).to receive(:full_text?).and_return(true)
      parent_object.solr_index_job
    end.to change { GoodJob::Job.where(queue: 'intensive_solr_index').count }.by(1)
  end
end
