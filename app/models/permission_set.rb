# frozen_string_literal: true
class PermissionSet < ApplicationRecord
  has_many :permission_requests
  resourcify
  validates :key, presence: true
  validates :label, presence: true

  def add_approver(user)
    remove_administrator(user) if user.administrator(self)
    user.add_role(:approver, self)
  end

  def remove_approver(user)
    user.remove_role(:approver, self)
  end

  def add_administrator(user)
    remove_approver(user) if user.approver(self)
    user.add_role(:administrator, self)
  end

  def remove_administrator(user)
    user.remove_role(:administrator, self)
  end
end
