# frozen_string_literal: true

class NotificationsController < ApplicationController
  before_action :set_notification, only: [:show, :edit, :update, :destroy, :update_metadata]

  def index
    @notifications = current_user.notifications.newest_first.page params[:page]
  end

  def destroy
    @notification.destroy
    respond_to do |format|
      format.html { redirect_to notifications_url, notice: 'Notification was resolved.' }
      format.json { head :no_content }
    end
  end

  def resolve_all
    current_user.notifications.newest_first.destroy_all
    respond_to do |format|
      format.html { redirect_to notifications_url, notice: 'Notification was resolved.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_notification
    @notification = Notification.find(params[:id])
  end
end
