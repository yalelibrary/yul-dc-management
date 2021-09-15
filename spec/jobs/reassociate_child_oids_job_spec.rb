# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReassociateChildOidsJob, type: :job do
  def queue_adapter_for_test
    ActiveJob::QueueAdapters::DelayedJobAdapter.new
  end

  let(:metadata_job) { ReassociateChildOidsJob.new }

  it 'increments the job queue by one' do
    ActiveJob::Base.queue_adapter = :delayed_job
    expect do
      ReassociateChildOidsJob.perform_later(metadata_job)
    end.to change { Delayed::Job.count }.by(1)
  end

  context 'job fails' do
    let(:user) { FactoryBot.create(:user) }
    let(:batch_process) { FactoryBot.create(:batch_process, batch_action: 'reassociate child oids', user: user) }
    let(:metadata_source) { FactoryBot.create(:metadata_source) }

    it 'notifies on save failure' do
      allow(batch_process).to receive(:reassociate_child_oids).and_raise('boom!')
      expect { metadata_job.perform(batch_process) }.to change { IngestEvent.count }.by(1)
      expect(IngestEvent.last.reason).to eq "ReassociateChildOidsJob failed due to boom!"
      expect(IngestEvent.last.status).to eq "failed"
    end
  end
end
