class AddDigitizationFundingToParentObject < ActiveRecord::Migration[6.0]
  def change
    add_column :parent_objects, :digitization_funding_source, :string
  end
end
