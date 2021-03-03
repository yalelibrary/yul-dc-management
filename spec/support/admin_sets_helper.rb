# frozen_string_literal: true

module AdminSetsHelper
  # Setup rspec
  RSpec.configure do |config|
    config.before do
      FactoryBot.create(:admin_set, key: "brbl", label: "Beinecke", homepage: "http://test.com")
      FactoryBot.create(:admin_set, key: "sml", label: "Sterling", homepage: "http://test2.com")
    end
  end
end
