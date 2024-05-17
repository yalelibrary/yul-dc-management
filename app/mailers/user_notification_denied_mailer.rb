# frozen_string_literal: true

class UserNotificationDeniedMailer < ApplicationMailer
  default from: "do_not_reply@library.yale.edu"

  def user_notification_denied_email
    @user_notification = params[:user_notification]
    mail(to: @user_notification[:request_user_email], subject: "Your request to view #{@user_notification[:parent_object_title]} has been denied")
  end
end
