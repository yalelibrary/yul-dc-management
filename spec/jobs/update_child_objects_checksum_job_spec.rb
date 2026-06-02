# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UpdateChildObjectsChecksumJob, type: :job do
  before do
    ActiveJob::Base.queue_adapter = GoodJob::Adapter.new(execution_mode: :external)
  end

  let(:user) { FactoryBot.create(:user) }
  let(:batch_process) { FactoryBot.create(:batch_process, user: user) }
  let(:update_child_objects_job) { UpdateChildObjectsChecksumJob.new }

  context 'when update_child_objects_checksum raises an exception' do
    let(:error_message) { 'Something went wrong' }
    let(:error) { StandardError.new(error_message) }

    before do
      allow(batch_process).to receive(:update_child_objects_checksum).and_raise(error)
      allow(batch_process).to receive(:batch_processing_event)
    end

    it 'logs the error with batch_processing_event without crashing' do
      expect(batch_process).to receive(:batch_processing_event)
        .with("Update child objects checksum job failed to process: #{error_message}", "failed")

      expect do
        described_class.new.perform(batch_process)
      end.not_to raise_error
    end

    it "has correct priority" do
      update_child_objects_job = described_class.new
      expect(update_child_objects_job.default_priority).to eq(60)
    end
  end
end
