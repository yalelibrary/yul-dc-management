# frozen_string_literal: true

class ReoccurringJobsController < ApplicationController
  def index
    @reoccurring_jobs = ActivityStreamLog.all
    respond_to do |format|
      format.html
      format.json { render json: ReoccurringJobDatatable.new(params, view_context: view_context) }
    end
  end

  # POST ActivityStreamReader
  def create
    if ActivityStreamLog.where(status: "Running").exists?
      respond_to do |format|
        format.html { redirect_to reoccurring_jobs_url, notice: 'An update is already in progress.' }
        format.json { head :no_content }
      end
    else
      ActivityStreamManualJob.perform_later
      respond_to do |format|
        format.html { redirect_to reoccurring_jobs_url, notice: 'Metadata update queued.' }
        format.json { head :no_content }
      end
    end
  end
end
