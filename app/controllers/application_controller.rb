# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  rescue_from CanCan::AccessDenied do |exception|
    @error_message = exception.message
    render plain: "Access denied", status: 401
  end

  protected

    def authenticate_user!
      if user_signed_in?
        super
      else
        redirect_to user_cas_omniauth_authorize_path
      end
    end
end
