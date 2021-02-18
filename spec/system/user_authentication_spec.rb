# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'User Authentication', type: :system, js: false, clean: true do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { FactoryBot.create(:user) }

  context 'an unauthenticated user' do
    it 'gets the link for Yale CAS authentication' do
      visit root_path
      expect(page).to have_button('You must sign in')
    end
  end

  context 'an authenticated user' do
    it 'gets a logout option' do
      login_as user
      visit root_path
      expect(page).to have_link('Sign Out', href: '/sign_out')
    end

    it 'expires the user session' do
      login_as user
      visit root_path
      travel(31.minutes)
      visit root_path
      expect(page).to have_button('You must sign in')
      travel_back
    end
  end
end
