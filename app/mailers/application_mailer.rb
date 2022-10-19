# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: "do_not_reply@library.yale.edu"
  layout 'mailer'
end
