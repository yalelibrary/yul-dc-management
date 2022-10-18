# frozen_string_literal: true

class ProblemReportsController < ApplicationController
  # GET /problem_reports
  # GET /problem_reports.json
  def index
    authorize!(:read, ProblemReport)
    respond_to do |format|
      format.html
      format.json { render json: ProblemReportDatatable.new(params, view_context: view_context, current_ability: current_ability) }
    end
  end

  def new
    authorize!(:create, ProblemReport)
    ProblemReportJob.perform_later(ProblemReport.create(status: "Queued"))
    redirect_to problem_reports_url
  end

  private

    # Only allow a list of trusted parameters through.
    def problem_report_params
      params.require(:problem_report).permit(:child_count, :parent_count, :problem_parent_count, :problem_child_count)
    end
end
