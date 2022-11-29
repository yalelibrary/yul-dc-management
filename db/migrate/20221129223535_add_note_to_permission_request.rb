class AddNoteToPermissionRequest < ActiveRecord::Migration[6.0]
  def change
    add_column :permission_requests, :user_note, :text
  end
end
