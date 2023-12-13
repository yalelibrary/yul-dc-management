# frozen_string_literal: true
require 'rails_helper'

RSpec.describe GenerateOutputCsvJob, type: :job do
  before do
    allow(GoodJob).to receive(:preserve_job_records).and_return(true)
    ActiveJob::Base.queue_adapter = GoodJob::Adapter.new(execution_mode: :inline)
  end

  let(:user) { FactoryBot.create(:user) }
  let(:batch_process) { FactoryBot.create(:batch_process, user: user) }

  it 'increments the job queue by one' do
    generate_output_csv_job = described_class.perform_later(batch_process)
    expect(generate_output_csv_job.instance_variable_get(:@successfully_enqueued)).to be true
  end

  it 'calls child_output_csv when performed' do
    expect(batch_process).to receive(:child_output_csv).once
    described_class.new.perform(batch_process)
  end

  it 'reports error when child_output_csv fails' do
    allow(batch_process).to receive(:child_output_csv).and_raise('boom!')
    inst = described_class.new
    expect do
      inst.perform(batch_process)
    end.to raise_error('boom!')
  end
end
