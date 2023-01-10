# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProblemReportMailer, type: :mailer do
  describe 'notify' do
    let(:csv) { "test,test,test\n1,1,1" }
    let(:problem_report) do
      ProblemReport.new(
        child_count: 1000,
        parent_count: 50,
        problem_child_count: 20,
        problem_parent_count: 4,
        status: 'Complete'
      )
    end
    let(:mail) { ProblemReportMailer.with(problem_report: problem_report).problem_report_email('not_real_address@yale.edu', csv) }

    it 'renders the expected fields' do
      expect(mail.subject).to eq 'Digital Collections Daily Report'
      expect(mail.to).to eq ['not_real_address@yale.edu']
      expect(mail.from).to eq ['do_not_reply@library.yale.edu']
      expect(mail.body.encoded).to include('Problem Parent Count: 4')
    end
  end
end
