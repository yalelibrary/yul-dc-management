class AddExtentOfDigitizationToParentObjects < ActiveRecord::Migration[6.0]
  def change
    AddExtentOfDigitizationToParentObjectsJob.perform_later
  end
end
