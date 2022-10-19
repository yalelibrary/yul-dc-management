# frozen_string_literal: true

class ProblemReportDatatable < AjaxDatatablesRails::ActiveRecord
  extend Forwardable

  def_delegators :@view, :content_tag, :link_to

  def initialize(params, opts = {})
    @view = opts[:view_context]
    @current_ability = opts[:current_ability]
    super
  end

  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||= {
      status: { source: "ProblemReport.status", searchable: true, orderable: true },
      parent_count: { source: "ProblemReport.parent_count", searchable: false, orderable: false },
      child_count: { source: "ProblemReport.child_count", searchable: false, orderable: false },
      problem_parent_count: { source: "ProblemReport.problem_parent_count", searchable: false, orderable: false },
      problem_child_count: { source: "ProblemReport.problem_child_count", searchable: false, orderable: false },
      date: { source: "ProblemReport.created_at", searchable: false, orderable: true },
      report: { source: "ProblemReport.id", searchable: false, orderable: false }
    }
  end

  def data
    records.map do |problem_report|
      url = problem_report.s3_presigned_url
      {
        status: problem_report.status,
        child_count: problem_report.child_count,
        parent_count: problem_report.parent_count,
        problem_parent_count: problem_report.problem_parent_count,
        problem_child_count: problem_report.problem_child_count,
        date: problem_report.created_at,
        report: url ? link_to("Download", url) : "n/a"
      }
    end
  end

  def get_raw_records # rubocop:disable Naming/AccessorMethodName
    ProblemReport.all
  end
end
