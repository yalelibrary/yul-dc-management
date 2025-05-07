# frozen_string_literal: true

class ActivityStreamLogsController < ApplicationController
  # Allows FontAwesome icons to render
  content_security_policy(only: :index) do |policy|
    policy.script_src :self, :unsafe_inline
    policy.script_src_attr  :self, :unsafe_inline
    policy.script_src_elem  :self, :unsafe_inline
    policy.style_src :self, :unsafe_inline
    policy.style_src_elem :self, :unsafe_inline
  end
 
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
