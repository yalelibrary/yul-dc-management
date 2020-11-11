# frozen_string_literal: true

class User < ApplicationRecord
  devise :timeoutable, :omniauthable, omniauth_providers: [:cas]

  has_many :notifications, as: :recipient
  has_many :batch_processes, dependent: :destroy
end
