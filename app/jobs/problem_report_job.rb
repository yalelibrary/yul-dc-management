# frozen_string_literal: true

class ProblemReportJob < ApplicationJob
  def default_priority
    40
  end

  def perform
    ProblemReport.new.generate_child_problem_csv(true)
  end
end
