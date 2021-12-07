# frozen_string_literal: true
#

class DelayedJobDashboardController < ApplicationController
  def index
    res = Delayed::Job.connection.execute("select count(*) as total,
              sum(case when locked_at is not null and failed_at is null then 1 else 0 end) as working,
              sum(case when last_error is not null then 1 else 0 end) as failed,
              sum(case when attempts=0 and locked_at is null then 1 else 0 end) as pending
              from delayed_jobs").first
    @all_jobs_count = res['total']
    @working = res['working']
    @failed = res['failed']
    @pending = res['pending']
  end

  def failed_jobs
    @jobs = Delayed::Job.page(params[:page]).where("last_error is not null").order("run_at desc")
    @job_types = "Failed"
    render :jobs
  end

  def working_jobs
    @jobs = Delayed::Job.page(params[:page]).where("locked_at is not null and failed_at is null").order("run_at desc")
    @job_types = "Working"
    render :jobs
  end

  def pending_jobs
    @jobs = Delayed::Job.page(params[:page]).where("attempts=0 and locked_at is null").order("run_at desc")
    @job_types = "Pending"
    render :jobs
  end

  def show
    @job = Delayed::Job.find(params[:id])
    @handler = YAML.safe_load(@job.handler, [ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper])
  end

  def delete_job
    Delayed::Job.find(params[:id]).destroy
    flash[:notice] = "Job #{params[:id]} deleted."
    redirect_to dashboard_path
  end

  def requeue
    Delayed::Job.find(params[:id]).update!(run_at: Time.now.utc, last_error: nil)
    flash[:notice] = "Job was re-queued"
    redirect_to show_job_path(params[:id])
  end
end
