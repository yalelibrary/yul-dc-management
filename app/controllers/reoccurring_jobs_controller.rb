# frozen_string_literal: true

class ReoccurringJobsController < ApplicationController
  def index
    if params['check_status']
      @check_status = true
      @scheduled_job_exists = Delayed::Job.page(params[:page]).where('handler LIKE ?', '%job_class: ActivityStreamJob%').exists?
      @manual_job_exists = Delayed::Job.page(params[:page]).where('handler LIKE ?', '%job_class: ActivityStreamManualJob%').exists?
    end
    @reoccurring_jobs = ActivityStreamLog.all
    respond_to do |format|
      format.html
      format.json { render json: ReoccurringJobDatatable.new(params, view_context: view_context) }
    end
  end

  # POST ActivityStreamReader
  def create_recurring
    ActivityStreamJob.perform_later unless Delayed::Job.page(params[:page]).where('handler LIKE ?', '%job_class: ActivityStreamJob%').exists?
    respond_to do |format|
      format.html { redirect_to reoccurring_jobs_url, notice: 'The recurring job has been queued.' }
      format.json { head :no_content }
    end
  end

  # POST ActivityStreamReader
  def create
    if params['queue_recurring']
      create_recurring
    elsif ActivityStreamLog.where(status: "Running").exists?
      respond_to do |format|
        format.html { redirect_to reoccurring_jobs_url, notice: 'An update is already in progress.' }
        format.json { head :no_content }
      end
    else
      ActivityStreamManualJob.perform_later
      respond_to do |format|
        format.html { redirect_to reoccurring_jobs_url, notice: 'The manual job has been queued.' }
        format.json { head :no_content }
      end
    end
  end
end
