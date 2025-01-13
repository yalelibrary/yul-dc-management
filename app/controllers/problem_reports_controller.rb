# frozen_string_literal: true

class ProblemReportsController < ApplicationController
  # Allows FontAwesome icons to render on datatable
  content_security_policy(only: :index) do |policy|
    policy.script_src :self, :unsafe_inline
    policy.script_src_attr  :self, :unsafe_inline
    policy.script_src_elem  :self, :unsafe_inline
    policy.style_src :self, :unsafe_inline
    policy.style_src_elem :self, :unsafe_inline
  end

  # GET /problem_reports
  # GET /problem_reports.json
  def index
    authorize!(:read, ProblemReport)
    if params['check_status']
      @check_status = true
      @scheduled_job_exists = GoodJob::Job.page(params[:page]).where('job_class LIKE ?', '%ProblemReportJob%').exists?
      @manual_job_exists = GoodJob::Job.page(params[:page]).where('job_class LIKE ?', '%ProblemReportManualJob%').exists?
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
      ProblemReportJob.perform_now unless GoodJob::Job.page(params[:page]).where('job_class LIKE ?', '%ProblemReportJob%').exists?
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
