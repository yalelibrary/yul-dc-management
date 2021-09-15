class AddFulltextToChildObjects < ActiveRecord::Migration[6.0]
  def change
    add_column :child_objects, :full_text, :boolean, default:false
  end
end
