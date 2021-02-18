# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "ChildObjects", type: :system, js: true do
  let(:user) { FactoryBot.create(:user) }
  let(:user2) { FactoryBot.create(:user, deactivated: true) }
  before do
    login_as user
    visit users_path
  end

  describe "users datatable" do
    it "defaults to only display Active users" do
      user2.reload
      expect(page).to have_content(user.uid)
      expect(page).to have_no_content(user2.uid)
    end
  end
end
