# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SolrIndexJob, type: :job do
  def queue_adapter_for_test
    ActiveJob::QueueAdapters::DelayedJobAdapter.new
  end

  let(:parent_object) { FactoryBot.build(:parent_object, oid: '16797069') }

  it 'increments the job queue by one' do
    ActiveJob::Base.queue_adapter = :delayed_job
    expect do
      SolrIndexJob.perform_later(parent_object)
    end.to change { Delayed::Job.count }.by(1)
  end
end
