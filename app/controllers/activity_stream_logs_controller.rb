# frozen_string_literal: true

class ActivityStreamLogsController < ApplicationController
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable SafeNavigationChain
  def index
    if params['check_status']
      @check_status = true
      @expired_logger = true if ActivityStreamLog.last&.status == "Running" && ActivityStreamLog.last&.created_at&.to_datetime <= DateTime.current - 12.hours
    end
    respond_to do |format|
      format.html
      format.json { render json: ActivityStreamLogsDatatable.new(params, view_context: view_context) }
    end
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable SafeNavigationChain

  # POST ActivityStreamReader
  def create
    return unless params['reset_log']
    logger = ActivityStreamLog.where(status: "Running").last
    logger.status = "Manually Reset"
    logger.save!
  end
end
