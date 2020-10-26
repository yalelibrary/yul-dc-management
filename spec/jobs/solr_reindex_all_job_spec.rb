# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SolrReindexAllJob, type: :job, prep_metadata_sources: true, solr: true do
  def queue_adapter_for_test
    ActiveJob::QueueAdapters::DelayedJobAdapter.new
  end

  let(:parent_object) { FactoryBot.build(:parent_object, oid: '16797069') }

  it 'increments the job queue by one' do
    parent_object
    ActiveJob::Base.queue_adapter = :delayed_job
    expect do
      SolrReindexAllJob.perform_later
    end.to change { Delayed::Job.count }.by(1)
  end
end
