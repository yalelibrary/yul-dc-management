# frozen_string_literal: true

module AdminSetsHelper
  # Setup rspec
  RSpec.configure do |config|
    # Look the admin sets up by key rather than counting rows, so a leftover admin set from another
    # spec can't stop one of these from being created.
    config.before(prep_admin_sets: true) do
      AdminSet.find_by(key: "brbl") || FactoryBot.create(:admin_set, key: "brbl", label: "Beinecke Library", homepage: "http://collections.library.yale.edu/Beinecke")
      AdminSet.find_by(key: "sml") || FactoryBot.create(:admin_set, key: "sml", label: "Sterling Memorial Library", homepage: "http://collections.library.yale.edu/Sterling")
    end
  end
end
