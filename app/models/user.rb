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

  def find_role(role, admin_set)
    roles.find_by(name: role, resource_id: admin_set.id)
  end

  def sysadmin
    has_role?(:sysadmin)
  end

  def editor(admin_set)
    has_role?(:editor, admin_set)
  end

  def viewer(admin_set)
    has_role?(:viewer, admin_set)
  end

  def deactivate!
    deactivate
    save!
  end
end
