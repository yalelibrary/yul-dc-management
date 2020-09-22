# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "Prevent InfiniteRedirectError", type: :system do
  let(:user) { FactoryBot.create(:user) }

  # Written to fix this error: ERR_TOO_MANY_REDIRECTS
  context "as an unauthenticated user" do
    it "redirects to CAS" do
      visit root_path
      expect(page.body).to include "Management Dashboard"
    end
  end
end
