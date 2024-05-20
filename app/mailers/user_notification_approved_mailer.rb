# frozen_string_literal: true

class UserNotificationApprovedMailer < ApplicationMailer
  def user_notification_approved_email
    @user_notification = params[:user_notification]
    if @user_notification[:permission_set_label] == "kiss"
      mail(from: "kissingerpapers@gmail.com")
    else
      mail(from: "do_not_reply@library.yale.edu")
    end
    mail(to: @user_notification[:request_user_email], subject: "Your request to view #{@user_notification[:parent_object_title]} has been approved")
  end
end
