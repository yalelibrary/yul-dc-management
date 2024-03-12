# frozen_string_literal: true

class AccessChangeRequestMailer < ApplicationMailer
  default from: "do_not_reply@library.yale.edu"

  def access_change_request_email
    @access_change_request = params[:access_change_request]
    mail(to: 'digitalspecialcollections@yale.edu', subject: 'DCS Object Visibility Update Request')
  end
end
