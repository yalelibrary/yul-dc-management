class ChangeDateAndTimeCaptured < ActiveRecord::Migration[7.0]
  def change
    change_column :child_objects, :date_and_time_captured, :string
  end
end