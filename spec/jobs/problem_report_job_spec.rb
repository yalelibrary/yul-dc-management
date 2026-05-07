# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProblemReportJob, type: :job do
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
