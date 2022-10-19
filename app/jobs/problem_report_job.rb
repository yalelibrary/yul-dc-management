# frozen_string_literal: true

class ProblemReportJob < ApplicationJob
  repeat 'every day at 1am'

  def perform
    ProblemReport.new.generate_child_problem_csv(true)
  end
end
