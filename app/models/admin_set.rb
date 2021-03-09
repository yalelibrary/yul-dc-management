# frozen_string_literal: true
class AdminSet < ApplicationRecord
  resourcify
  validates :key, presence: true
  validates :label, presence: true
  validates :homepage, presence: true
  validates :homepage, format: URI.regexp(%w[http https])

  def add_viewer(user)
    remove_editor(user) if user.editor(self)
    user.add_role(:viewer, self)
  end

  def remove_viewer(user)
    user.remove_role(:viewer, self)
  end

  def add_editor(user)
    remove_viewer(user) if user.viewer(self)
    user.add_role(:editor, self)
  end

  def remove_editor(user)
    user.remove_role(:editor, self)
  end
end
