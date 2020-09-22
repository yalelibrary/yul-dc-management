# frozen_string_literal: true

class User < ApplicationRecord
  devise :omniauthable, omniauth_providers: [:cas]

  has_many :notifications, as: :recipient
end
