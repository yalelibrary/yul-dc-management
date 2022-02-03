class AddChecksumToChildObject < ActiveRecord::Migration[6.0]
  def change
    add_column :child_objects, :sha512_checksum, :string
  end
end
