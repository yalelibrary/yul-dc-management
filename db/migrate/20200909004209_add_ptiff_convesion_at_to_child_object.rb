class AddPtiffConvesionAtToChildObject < ActiveRecord::Migration[6.0]
  def change
    add_column :child_objects, :ptiff_conversion_at, :datetime

    # requeue all ptiff jobs to verify conversion and set date
    ChildObject.find_each do |c|
      GeneratePtiffJob.perform_later(c)
    end
  end
end
