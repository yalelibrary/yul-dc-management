# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProblemReportJob, type: :job do
  it "has correct priority" do
    problem_report_job = described_class.new
    expect(problem_report_job.default_priority).to eq(40)
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
      new_time = now + 1.day
      Timecop.travel(new_time)
      expect(GoodJob::CronEntry.all[1].instance_variable_get(:@params)).to eq({ cron: "15 0 * * *", class: "ProblemReportJob", key: :problem_report })
    end
  end
end
