# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include JwtWebToken
  before_action :authenticate_user!
  rescue_from CanCan::AccessDenied do |exception|
    @error_message = exception.message
    render plain: "Access denied", status: 401
  end

  def access_denied
    render(plain: 'Access denied', status: 401)
  end

  def check_authorization
    return unless request.headers['Authorization'] != "Bearer #{ENV['OWP_AUTH_TOKEN']}" || ENV['OWP_AUTH_TOKEN'].blank? || ENV['OWP_AUTH_TOKEN'].nil?
    render(json: { error: 'unauthorized' }.to_json,
           status: :unauthorized)
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
