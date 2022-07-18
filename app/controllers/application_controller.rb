# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include JwtWebToken
  before_action :authenticate_with_token, :authenticate_user!
  rescue_from CanCan::AccessDenied do |exception|
    @error_message = exception.message
    render plain: "Access denied", status: 401
  end

  def access_denied
    render(plain: 'Access denied', status: 401)
  end

  protected

    def authenticate_with_token
      header = request.headers['Authorization']
      header = header.split(' ').last if header
      return unless header
      decoded_token = jwt_decode(header)
      token_user = User.where(id: decoded_token[:user_id]).first
      return unless token_user&.active_for_authentication?
      sign_in token_user, event: :authentication # this will throw if @user is not activated
    end

    def authenticate_user!
      if user_signed_in?
        super
      else
        redirect_to user_cas_omniauth_authorize_path
      end
    end
end
