class UpdateArchiveSpaceDisplayName < ActiveRecord::Migration[6.1]
  def self.up
    MetadataSource.where(display_name: "ArchiveSpace").update_all(:display_name => 'ArchivesSpace')
  end
end
