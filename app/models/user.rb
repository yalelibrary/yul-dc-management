# frozen_string_literal: true

class User < ApplicationRecord
  rolify
  devise :timeoutable, :omniauthable, omniauth_providers: [:cas]

  validates :email, presence: true
  validates :first_name, presence: true
  validates :last_name, presence: true

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
