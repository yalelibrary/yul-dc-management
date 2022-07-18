# frozen_string_literal: true

require 'jwt'

module JwtWebToken
  extend ActiveSupport::Concern
  SECRET_KEY = Rails.application.secret_key_base

  def jwt_encode(payload, exp = 1.day.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY)
  end

  def jwt_decode(token)
    decoded = JWT.decode(token, SECRET_KEY)
    HashWithIndifferentAccess.new decoded[0]
  rescue
    {}
  end
end
