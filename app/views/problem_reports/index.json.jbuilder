# frozen_string_literal: true

json.array! @problem_reports, partial: "problem_reports/problem_report", as: :problem_report
