# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UpdateChildObjectsJob, type: :job do
  before do
    allow(GoodJob).to receive(:preserve_job_records).and_return(true)
    ActiveJob::Base.queue_adapter = GoodJob::Adapter.new(execution_mode: :external)
  end

  let(:user) { FactoryBot.create(:user) }
  let(:batch_process) { FactoryBot.create(:batch_process, user: user) }
  let(:update_child_objects_job) { UpdateChildObjectsJob.new }

  context 'when update_child_objects_caption raises an exception' do
    let(:error_message) { 'Something went wrong' }
    let(:error) { StandardError.new(error_message) }

    before do
      allow(batch_process).to receive(:update_child_objects_caption).and_raise(error)
      allow(batch_process).to receive(:batch_processing_event)
    end

    it 'logs the error with batch_processing_event' do
      expect(batch_process).to receive(:batch_processing_event)
        .with("Setup job failed to save: #{error_message}", "failed")

      expect do
        described_class.new.perform(batch_process)
      end.not_to raise_error
    end
  end
end
