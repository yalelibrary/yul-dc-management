# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  protected

    def authenticate_user!
      if user_signed_in?
        super
      else
        redirect_to user_cas_omniauth_authorize_path
      end
    end
end
