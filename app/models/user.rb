# frozen_string_literal: true

class User < ApplicationRecord
  devise :omniauthable, omniauth_providers: [:cas]

  has_many :notifications, as: :recipient
  has_many :batch_processes

  def active_for_authentication?
    super && !deactivated
  end

  def deactivate
    self.deactivated = true
  end

  def deactivate!
    deactivate
    save!
  end
end
