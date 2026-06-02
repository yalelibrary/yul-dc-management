# frozen_string_literal: true
require 'rails_helper'

RSpec.describe GenerateOutputCsvJob, type: :job do
  let(:user) { FactoryBot.create(:user) }
  let(:batch_process) { FactoryBot.create(:batch_process, user: user) }

  it 'increments the job queue by one' do
    generate_output_csv_job = described_class.perform_later(batch_process)
    expect(generate_output_csv_job.instance_variable_get(:@successfully_enqueued)).to be true
  end

  it "has correct priority" do
    generate_output_csv_job = described_class.new
    expect(generate_output_csv_job.default_priority).to eq(60)
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
