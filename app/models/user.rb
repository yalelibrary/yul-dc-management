# frozen_string_literal: true

class User < ApplicationRecord
  include JwtWebToken
  rolify
  devise :timeoutable, :omniauthable, omniauth_providers: [:cas]

  validates :email, presence: true
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :uid, uniqueness: { message: "already exists." }

  has_many :batch_processes
  has_many :users_roles
  has_many :permission_requests, class_name: "OpenWithPermission::PermissionRequest"

  after_update :remove_roles

  # Devise 5.0.4's serialize_from_session(key, salt) has a fixed 2-arg arity, but
  # Warden calls it as serialize_from_session(*stored_key). Cookies written by older
  # Devise/Rails versions can store a 1- or 3-element key, which raises ArgumentError
  # on read and 500s the request. Accept any arity, extract the id defensively, and
  # treat anything unreadable as "no session" so a stale cookie logs the user out
  # instead of crashing. See: https://github.com/heartcombo/devise/issues/5752
  def self.serialize_from_session(*args)
    key = args.first
    record_id =
      case key
      when Hash  then key["id"] || key[:id]
      when Array then Array(key).flatten.first
      else key
      end
    return nil if record_id.blank?

    find_by(id: record_id)
  rescue StandardError => e
    Rails.logger.warn("serialize_from_session: discarding unreadable session (#{e.class}: #{e.message})")
    nil
  end

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
        remove_role(role.name, role.resource_type == 'AdminSet' ? AdminSet.find(role.resource_id) : OpenWithPermission::PermissionSet.find(role.resource_id))
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
