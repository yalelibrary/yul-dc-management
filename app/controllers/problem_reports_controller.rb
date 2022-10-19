# frozen_string_literal: true

class ProblemReportsController < ApplicationController
  # GET /problem_reports
  # GET /problem_reports.json
  def index
    authorize!(:read, ProblemReport)
    if params['check_status']
      @check_status = true
      @scheduled_job_exists = Delayed::Job.page(params[:page]).where('handler LIKE ?', '%job_class: ProblemReportJob%').exists?
      @manual_job_exists = Delayed::Job.page(params[:page]).where('handler LIKE ?', '%job_class: ProblemReportManualJob%').exists?
    end
    @email_address = ENV['INGEST_ERROR_EMAIL'].presence
    respond_to do |format|
      format.html
      format.json { render json: ProblemReportDatatable.new(params, view_context: view_context, current_ability: current_ability) }
    end
  end

  def create
    authorize!(:create, ProblemReport)
    if params['queue_recurring']
      ProblemReportJob.perform_now unless Delayed::Job.page(params[:page]).where('handler LIKE ?', '%job_class: ProblemReportJob%').exists?
      respond_to do |format|
        format.html { redirect_to problem_reports_url, notice: 'The daily problem report job has been queued.' }
        format.json { head :no_content }
      end
    else
      ProblemReportManualJob.perform_later(ProblemReport.create(status: "Queued"))
      respond_to do |format|
        format.html { redirect_to problem_reports_url, notice: 'The manual problem report job has been queued.' }
        format.json { head :no_content }
      end
    end
  end

  private

    # Only allow a list of trusted parameters through.
    def problem_report_params
      params.require(:problem_report).permit(:child_count, :parent_count, :problem_parent_count, :problem_child_count)
    end
end
