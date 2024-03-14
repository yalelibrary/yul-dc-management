# frozen_string_literal: true

class NewPermissionRequestMailer < ApplicationMailer
  default from: "do_not_reply@library.yale.edu"

  def new_permission_request_email
    @new_permission_request = params[:new_permission_request]
    permission_set = OpenWithPermission::PermissionSet.find_by(label: @new_permission_request[:permission_set_label])
    admins_and_approvers = []
    User.all.each do |user|
      admins_and_approvers << user if user.has_role?(:administrator, permission_set) || user.has_role?(:approver, permission_set)
    end
    admins_and_approvers.each do |user|
      @new_permission_request[:approver_name] = user.first_name + ' ' + user.last_name
      mail(to: user.email, subject: "New Permission Request for #{@new_permission_request[:permission_set_label]}")
    end
  end
end
