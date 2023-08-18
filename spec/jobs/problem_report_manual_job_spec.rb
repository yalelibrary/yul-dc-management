# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProblemReportManualJob, type: :job do
  before do
    allow(GoodJob).to receive(:preserve_job_records).and_return(true)
    ActiveJob::Base.queue_adapter = GoodJob::Adapter.new(execution_mode: :inline)
  end

  let(:problem_report) { FactoryBot.create(:problem_report) }

  let(:problem_report_job) { described_class.new }

  it 'increments the job queue by one' do
    expect do
      described_class.perform_later(problem_report)
    end.to change { GoodJob::Job.count }.by(1)
  end

  it 'generates the report when run' do
    expect(problem_report).to receive(:generate_child_problem_csv).once
    problem_report_job.perform(problem_report)
  end
end
