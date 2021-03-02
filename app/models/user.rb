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

  def sysadmin=(value)
    if value.present? && value && value != '0'
      add_role :sysadmin
    else
      remove_role :sysadmin
    end
  end

  def sysadmin
    has_role?(:sysadmin)
  end

  def editor=(value)
    if value.present? && value && value != '0'
      add_role :editor
    else
      remove_role :editor
    end
  end

  def editor
    has_role?(:editor)
  end

  def viewer=(value)
    if value.present? && value && value != '0'
      add_role :viewer
    else
      remove_role :viewer
    end
  end

  def viewer
    has_role?(:viewer)
  end

  def deactivate!
    deactivate
    save!
  end
end
