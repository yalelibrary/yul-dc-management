# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UpdateStructureRangesJob, type: :job, prep_admin_sets: true, prep_metadata_sources: true do
  let(:structure_job) { described_class.new }
  let(:user) { FactoryBot.create(:user) }
  let(:batch_process) { FactoryBot.create(:batch_process, batch_action: 'update structure ranges', user: user) }

  it 'increments the job queue by one' do
    update_structure_ranges_job = described_class.perform_later(batch_process)
    expect(update_structure_ranges_job.instance_variable_get(:@successfully_enqueued)).to be true
  end

  it "has correct priority" do
    expect(described_class.new.default_priority).to eq(20)
  end

  it 'delegates to the batch process' do
    expect(batch_process).to receive(:update_structure_ranges)
    structure_job.perform(batch_process)
  end

  context 'job fails' do
    it 'notifies on save failure' do
      allow(batch_process).to receive(:update_structure_ranges).and_raise('boom!')
      expect { structure_job.perform(batch_process) }.to change { IngestEvent.count }.by(1)
      expect(IngestEvent.last.reason).to eq "UpdateStructureRangesJob failed due to boom!"
      expect(IngestEvent.last.status).to eq "failed"
    end
  end
end
