# frozen_string_literal: true

class ProblemReportMailer < ApplicationMailer
  default from: "do_not_reply@library.yale.edu"

  def problem_report_email(email, csv)
    @problem_report = params[:problem_report]
    attachments['report.csv'] = { mime_type: 'text/csv',
                                  content: csv }
    mail(to: email, subject: 'Digital Collections Daily Report')
  end
end
