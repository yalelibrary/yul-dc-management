# frozen_string_literal: true

class NewPermissionRequestMailer < ApplicationMailer
  default from: "do_not_reply@library.yale.edu"

  def new_permission_request_email(approver_or_admin_email)
    @new_permission_request = params[:new_permission_request]
    mail(to: approver_or_admin_email, subject: "New Permission Request for #{@new_permission_request[:permission_set_label]}")
  end
end
