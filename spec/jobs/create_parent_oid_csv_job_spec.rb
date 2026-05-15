# frozen_string_literal: true
require 'rails_helper'

RSpec.describe CreateParentOidCsvJob, type: :job do
  before do
    ActiveJob::Base.queue_adapter = GoodJob::Adapter.new(execution_mode: :external)
  end

  let(:user) { FactoryBot.create(:user) }
  let(:batch_process) { FactoryBot.create(:batch_process, user: user) }
  let(:create_parent_oid_csv_job) { CreateParentOidCsvJob.new }

  it 'increments the job queue by one' do
    csv_job = described_class.perform_later(batch_process)
    expect(csv_job.instance_variable_get(:@successfully_enqueued)).to eq true
  end

  it "has correct priority" do
    expect(create_parent_oid_csv_job.default_priority).to eq(60)
  end

  it "has correct queue" do
    expect(create_parent_oid_csv_job.queue_name).to eq('default')
  end

  it 'calls parent_output_csv when performed' do
    expect(batch_process).to receive(:parent_output_csv).once
    described_class.new.perform(batch_process)
  end

  context 'when parent_output_csv raises an exception' do
    let(:error_message) { 'Something went wrong' }
    let(:error) { StandardError.new(error_message) }

    before do
      allow(batch_process).to receive(:parent_output_csv).and_raise(error)
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
