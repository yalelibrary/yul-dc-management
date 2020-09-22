# frozen_string_literal: true

class User < ApplicationRecord
  devise :omniauthable, omniauth_providers: [:cas]

  has_many :notifications, as: :recipient

  def self.from_cas(cas_auth_hash)
    User.find_or_create_by(uid: cas_auth_hash.uid, provider: cas_auth_hash.provider)
  end
end
