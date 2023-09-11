# frozen_string_literal: true

module AdminSetsHelper
  # Setup rspec
  RSpec.configure do |config|
    config.before(prep_admin_sets: true) do
      FactoryBot.create(:admin_set, key: "brbl", label: "Beinecke Library", homepage: "http://test.com") if AdminSet.all.count == 0
      FactoryBot.create(:admin_set, key: "sml", label: "Sterling Memorial Library", homepage: "http://test2.com") if AdminSet.all.count == 1
    end
  end
end
