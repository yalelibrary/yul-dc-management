# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReassociateChildOidsJob, type: :job, prep_admin_sets: true, prep_metadata_sources: true do
  let(:metadata_job) { ReassociateChildOidsJob.new }
  let(:user) { FactoryBot.create(:user) }
  let(:batch_process) { FactoryBot.create(:batch_process, batch_action: 'reassociate child oids', user: user) }

  it 'increments the job queue by one' do
    reassociate_child_oids_job = described_class.perform_later(batch_process)
    expect(reassociate_child_oids_job.instance_variable_get(:@successfully_enqueued)).to be true
  end

  it "has correct priority" do
    reassociate_child_oids_job = described_class.new
    expect(reassociate_child_oids_job.default_priority).to eq(60)
  end

  context 'job fails' do
    let(:metadata_source) { MetadataSource.first }

    it 'notifies on save failure' do
      allow(batch_process).to receive(:reassociate_child_oids).and_raise('boom!')
      expect { metadata_job.perform(batch_process) }.to change { IngestEvent.count }.by(1)
      expect(IngestEvent.last.reason).to eq "ReassociateChildOidsJob failed due to boom!"
      expect(IngestEvent.last.status).to eq "failed"
    end
  end
end
