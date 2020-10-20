class RemoveChildHeightAndWidthThatAreZero < ActiveRecord::Migration[6.0]
  def change
    ChildObject.where("height < ? OR width < ?", 1, 1).find_each do |child|
      child.height = nil
      child.width = nil
      child.ptiff_conversion_at = nil
      child.parent_object.generate_manifest = true
      child.parent_object.solr_delete
      GeneratePtiffJob.perform_later(child)
    end
  end
end
