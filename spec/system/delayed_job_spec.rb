# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'Delayed Jobs', type: :system, js: true do
  let(:sysadmin_user) { FactoryBot.create(:sysadmin_user) }
  let(:user) { FactoryBot.create(:user) }

  context 'as a logged out visitor' do
    it 'are inaccessible through the delayed jobs dashboard menu item' do
      visit root_path
      expect(page).not_to have_content('Delayed Job Dashboard')
    end
    # TODO(alishaevn): figure out why this spec is failing
    xit 'are inaccessible manually through the delayed jobs endpoint' do
      visit delayed_job_web_path
      # visit delayed_job_path
      # byebug
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

    it 'are inaccessible through the delayed jobs dashboard menu item' do
      visit root_path
      expect(page).not_to have_content('Delayed Job Dashboard')
    end
    it 'are inaccessible manually through the delayed jobs endpoint' do
      visit delayed_job_web_path
      expect(current_path).to eq(delayed_job_web_path)
      expect(page).to have_content('Access denied')
    end
  end

  context 'as a logged in user who is a sysadmin' do
    before do
      login_as sysadmin_user
    end

    it 'are accessible through the delayed jobs dashboard menu item' do
      visit root_path
      expect(page).to have_content('DELAYED JOB DASHBOARD')
    end
    it 'are accessible manually through the delayed jobs endpoint' do
      visit delayed_job_web_path
      expect(page).to have_content('Overview')
    end
  end
end
