# frozen_string_literal: true
require 'rails_helper'

RSpec.describe CreateParentOidCsvJob, type: :job do
  before do
    allow(GoodJob).to receive(:preserve_job_records).and_return(true)
    ActiveJob::Base.queue_adapter = GoodJob::Adapter.new(execution_mode: :inline)
  end

  let(:user) { FactoryBot.create(:user) }
  let(:batch_process) { FactoryBot.create(:batch_process, user: user) }
  let(:create_parent_oid_csv_job) { CreateParentOidCsvJob.new }

  it 'increments the job queue by one' do
    ActiveJob::Base.queue_adapter = :good_job
    expect do
      described_class.perform_later(batch_process)
    end.to change { GoodJob::Job.count }.by(1)
  end

  it "has correct priority" do
    expect(create_parent_oid_csv_job.default_priority).to eq(-100)
  end

  it "has correct queue" do
    expect(create_parent_oid_csv_job.queue_name).to eq('default')
  end

  it 'calls parent_output_csv when performed' do
    expect(batch_process).to receive(:parent_output_csv).once
    described_class.new.perform(batch_process)
  end

  it 'reports error when parent_output_csv fails' do
    allow(batch_process).to receive(:parent_output_csv).and_raise('boom!')
    inst = described_class.new
    expect do
      inst.perform(batch_process)
    end.to raise_error('boom!')
  end
end
