# frozen_string_literal: true

class ProblemReportJob < ApplicationJob
  queue_as :default

  def default_priority
    -100
  end

  def perform(problem_report)
    problem_report.generate_child_problem_csv
  end
end
