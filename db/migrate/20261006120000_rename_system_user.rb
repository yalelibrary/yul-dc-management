# frozen_string_literal: true

class RenameSystemUser < ActiveRecord::Migration[7.2]
  def up
    User.find_by(uid: 'System')&.update!(first_name: 'System', last_name: 'User')
  end

  def down; end
end
