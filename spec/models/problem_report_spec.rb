# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProblemReport, type: :model do
  let(:problem_report) { FactoryBot.create(:problem_report) }
  let(:csv) { "1,2,3\n4,5,6" }

  it "has all expected fields" do
    expect(problem_report.child_count).to eq 1
    expect(problem_report.parent_count).to eq 1
    expect(problem_report.problem_parent_count).to eq 1
    expect(problem_report.problem_child_count).to eq 1
  end

  context "if Email is set" do
    around do |example|
      original_email = ENV["INGEST_ERROR_EMAIL"]
      ENV["INGEST_ERROR_EMAIL"] = "test@yale.edu"
      example.run
      ENV["INGEST_ERROR_EMAIL"] = original_email
    end

    it "sends an email" do
      message_delivery = instance_double(ActionMailer::MessageDelivery)
      mailer = instance_double(ProblemReportMailer)
      expect(ProblemReportMailer).to receive(:with).and_return(mailer)
      allow(message_delivery).to receive(:deliver_later)
      allow(mailer).to receive(:problem_report_email).and_return message_delivery
      problem_report.send_report_email(csv)
    end
  end

  context "if Email is not set" do
    around do |example|
      original_email = ENV["INGEST_ERROR_EMAIL"]
      ENV["INGEST_ERROR_EMAIL"] = nil
      example.run
      ENV["INGEST_ERROR_EMAIL"] = original_email
    end

    it "doesn't try to send an email" do
      expect(ProblemReportMailer). not_to receive(:with)
      problem_report.send_report_email(csv)
    end
  end
end
