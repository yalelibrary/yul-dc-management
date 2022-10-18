# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProblemReportJob, type: :job do
  def queue_adapter_for_test
    ActiveJob::QueueAdapters::DelayedJobAdapter.new
  end

  let(:problem_report) { FactoryBot.create(:problem_report) }

  let(:problem_report_job) { described_class.new }

  it 'increments the job queue by one' do
    ActiveJob::Base.queue_adapter = :delayed_job
    expect do
      described_class.perform_later(problem_report)
    end.to change { Delayed::Job.count }.by(1)
  end

  it 'generates the report when run' do
    expect(problem_report).to receive(:generate_child_problem_csv).once
    problem_report_job.perform(problem_report)
  end
end
