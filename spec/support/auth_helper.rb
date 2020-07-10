# frozen_string_literal: true

module AuthHelper
  def login_header(user)
    ec = ActionController::HttpAuthentication::Basic.encode_credentials(user.email, user.password)
    { 'HTTP_AUTHORIZATION' => ec }
  end
end
