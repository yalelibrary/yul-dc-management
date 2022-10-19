# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/user
class ProblemReportMailerPreview < ActionMailer::Preview
  def problem_report_email
    csv = "test,test,test\n1,1,1"
    problem_report = ProblemReport.new
    problem_report.child_count = 1000
    problem_report.parent_count = 50
    problem_report.problem_parent_count = 4
    problem_report.problem_child_count = 20
    problem_report.status = "Complete"
    problem_report.created_at = Time.zone.now
    problem_report.updated_at = Time.zone.now
    ProblemReportMailer.with(problem_report: problem_report).problem_report_email("not_real_address@yale.edu", csv)
  end
end
