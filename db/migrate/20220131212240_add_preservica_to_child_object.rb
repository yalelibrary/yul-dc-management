class AddPreservicaToChildObject < ActiveRecord::Migration[6.0]
  def change
    add_column :child_objects, :preservica_content_object_uri, :text
    add_column :child_objects, :preservica_generation_uri, :text
    add_column :child_objects, :preservica_bitstream_uri, :text
    add_index  :child_objects, :preservica_content_object_uri unless index_exists?(:child_objects, :preservica_content_object_uri)
    add_index  :child_objects, :preservica_generation_uri unless index_exists?(:child_objects, :preservica_generation_uri)
    add_index  :child_objects, :preservica_bitstream_uri unless index_exists?(:child_objects, :preservica_bitstream_uri)
  end
end
