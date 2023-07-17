# frozen_string_literal: true

class User < ApplicationRecord
  include JwtWebToken
  rolify
  devise :timeoutable, :omniauthable, omniauth_providers: [:cas]

  validates :email, presence: true
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :uid, uniqueness: { message: "already exists." }

  has_many :batch_processes, , dependent: :nullify
  has_many :users_roles, dependent: :delete_all
  has_many :permission_requests, dependent: :delete_all

  after_update :remove_roles

  def self.system_user
    system_user = User.find_by_uid('System')
    unless system_user
      system_user = User.new(uid: 'System', email: 'test@example.com', first_name: 'test', last_name: 'user')
      Rails.logger.error("Unable to save system user") unless system_user.save!
    end
    system_user
  end

  def active_for_authentication?
    super && !deactivated
  end

  def deactivate
    self.deactivated = true
  end

  def remove_roles
    return unless deactivated
    roles.each do |role|
      if role.name == 'sysadmin'
        remove_role :sysadmin
      else
        remove_role(role.name, role.resource_type == 'AdminSet' ? AdminSet.find(role.resource_id) : PermissionSet.find(role.resource_id))
      end
    end
  end

  def token
    info = { user_id: id }
    jwt_encode(info)
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

  def administrator(permission_set)
    has_role?(:administrator, permission_set)
  end

  def approver(permission_set)
    has_role?(:approver, permission_set)
  end

  def viewer(admin_set)
    has_role?(:viewer, admin_set)
  end

  def deactivate!
    deactivate
    save!
  end

  def full_name
    "#{first_name} #{last_name}"
  end
end
