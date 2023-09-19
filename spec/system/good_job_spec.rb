# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'GoodJob Jobs', type: :system, js: true do
  let(:sysadmin_user) { FactoryBot.create(:sysadmin_user) }
  let(:user) { FactoryBot.create(:user) }

  context 'as a logged out visitor' do
    it 'are inaccessible through the good jobs dashboard menu item' do
      visit root_path
      expect(page).not_to have_content('GoodJob Job Dashboard')
    end
    # TODO(alishaevn): figure out why this spec is failing
    xit 'are inaccessible manually through the good jobs endpoint' do
      visit jobs_path
      # visit good_job_path
      # this spec keeps failing with:
      # ActionController::RoutingError: No route matches [GET] "/management/users/auth/cas"
      expect(current_path).to eq(user_cas_omniauth_authorize_path)
      expect(page).to have_content('Not found. Authentication passthru.')
    end
  end

  context 'as a logged in user who is not a sysadmin' do
    before do
      login_as user
    end

    it 'are inaccessible through the good jobs dashboard menu item' do
      visit root_path
      expect(page).not_to have_content('GoodJob Job Dashboard')
    end
    it 'are inaccessible manually through the good jobs endpoint' do
      visit jobs_path
      expect(current_path).to eq('/users/auth/cas')
      expect(page).to have_content('Authentication passthru')
    end
  end

  context 'as a logged in user who is a sysadmin' do
    before do
      login_as sysadmin_user
    end

    it 'are accessible through the good jobs dashboard menu item' do
      visit root_path
      expect(page).to have_content('GoodJob Job Dashboard')
    end
    it 'are accessible manually through the good jobs endpoint' do
      visit jobs_path
      expect(page).to have_content('Jobs')
    end
  end
end
