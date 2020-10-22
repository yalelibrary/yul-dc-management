class RemoveChildHeightAndWidthThatAreZero < ActiveRecord::Migration[6.0]
  def change
    RemoveZerosFromChildObjectsJob.perform_later
  end
end
