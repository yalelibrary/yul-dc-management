# frozen_string_literal: true

class User < ApplicationRecord
  devise :omniauthable, omniauth_providers: [:cas]

  has_many :notifications, as: :recipient
  has_many :batch_processes, as: :current_user
end
