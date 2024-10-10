class UpdateDigitalObjectSource < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.connection.execute("UPDATE parent_objects SET digital_object_source = 'None' WHERE digital_object_source IS NULL")
  end
end
