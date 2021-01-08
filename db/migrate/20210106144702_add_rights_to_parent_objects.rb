class AddRightsToParentObjects < ActiveRecord::Migration[6.0]
  def change
    AddRightsToParentObjectsJob.perform_later
  end
end
