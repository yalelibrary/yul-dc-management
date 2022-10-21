# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProblemReportJob, type: :job do

  def queue_adapter_for_test
    ActiveJob::QueueAdapters::DelayedJobAdapter.new
  end

  describe "jumping ahead one day" do
    before do
      Timecop.freeze(Time.zone.today)
    end

    after do
      Timecop.return
    end

    it "increments job queue once per day" do
      now = Time.zone.today
      ActiveJob::Scheduler.start
      new_time = now + 1.day
      Timecop.travel(new_time)
      expect(Delayed::Job.where('handler LIKE ?', '%job_class: ProblemReportJob%').count).to eq 1
    end
  end
end
