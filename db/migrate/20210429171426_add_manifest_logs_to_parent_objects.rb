class AddManifestLogsToParentObjects < ActiveRecord::Migration[6.0]
  def change
    add_column(:parent_objects, :manifest_logs, :text)
  end
end
