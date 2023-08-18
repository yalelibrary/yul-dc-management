# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UpdateParentObjectsJob, type: :job do
  before do
    allow(GoodJob).to receive(:preserve_job_records).and_return(true)
    ActiveJob::Base.queue_adapter = GoodJob::Adapter.new(execution_mode: :inline)
  end

  let(:metadata_job) { UpdateParentObjectsJob.new }

  it 'increments the job queue by one' do
    ActiveJob::Base.queue_adapter = :good_job
    expect do
      UpdateParentObjectsJob.perform_later(metadata_job)
    end.to change { GoodJob::Job.count }.by(1)
  end
end
