# frozen_string_literal: true

class ReoccurringJobsController < ApplicationController
  def index
    @reoccuring_jobs = ActivityStreamLog.all
    respond_to do |format|
      format.html
      format.json { render json: ReoccurringJobDatatable.new(params, view_context: view_context) }
    end
  end

  # GET /reoccuring_jobs/1
  # GET /reoccuring_jobs/1.json
  def show
    respond_to do |format|
      format.html
      format.json { render json: ReoccuringJobDatatable.new(params, view_context: view_context) }
    end
  end

  # GET /reoccuring_jobs/new
  def new
    ActivityStreamReader.update
  end

  # GET /reoccuring_jobs/1/edit
  def edit; end

end
