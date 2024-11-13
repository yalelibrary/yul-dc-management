class AddNewChecksumFields < ActiveRecord::Migration[7.0]
  def change
    add_column :child_objects, :sha256_checksum, :string
    add_column :child_objects, :md5_checksum, :string
    add_column :child_objects, :file_size, :bigint
  end
end
