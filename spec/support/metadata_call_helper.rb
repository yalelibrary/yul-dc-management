# frozen_string_literal: true

module MetdataCallHelper
  def prep_metadata_call
    FactoryBot.create(:metadata_source)
    FactoryBot.create(:metadata_source_voyager)
    FactoryBot.create(:metadata_source_aspace)
  end
end
