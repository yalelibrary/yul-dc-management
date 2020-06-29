# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "Database Tasks", type: :system do
  describe 'Click Seed Database button' do
    before do
      visit management_index_path
    end
    it "can run a test" do
      expect(ParentObject.count).to eq 0
      click_on("Update Database")
      expect(ParentObject.count).to be > 40
    end
  end
end
