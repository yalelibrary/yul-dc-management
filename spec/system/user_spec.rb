# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'Users', type: :system, js: true do
  let(:user) { FactoryBot.create(:user) }
  let(:user2) { FactoryBot.create(:user) }

  before do
    login_as user
  end

  describe 'datatable' do
    it 'defaults to only display Active users' do
      user2.reload
      visit users_path
      expect(page).to have_content(user.uid)
      expect(page).to have_content(user2.uid)
    end
  end

  describe 'are editable' do
    it 'and require an email to be present' do
      visit users_path
      click_on('Edit')
      fill_in('Email', with: '')
      click_on('Update User')

      message = page.find('#user_email').native.attribute('validationMessage')

      expect(message).to eq 'Please fill out this field.'
      expect(current_path).to eq edit_user_path(user.id)
    end

    it 'and require their full name to be present' do
      visit users_path
      click_on('Edit')
      fill_in('First name', with: '')
      click_on('Update User')

      message = page.find('#user_first_name').native.attribute('validationMessage')

      expect(message).to eq 'Please fill out this field.'
      expect(current_path).to eq edit_user_path(user.id)

      fill_in('First name', with: 'Aaliyah')
      fill_in('Last name', with: '')
      click_on('Update User')

      message = page.find('#user_last_name').native.attribute('validationMessage')

      expect(message).to eq 'Please fill out this field.'
      expect(current_path).to eq edit_user_path(user.id)
    end

    it 'and can be deactivated' do
      visit edit_user_path(user2.id)
      page.check('Deactivated')
      click_on('Update User')
      visit users_path

      expect(page).to have_content(user.uid)
      expect(page).to have_no_content(user2.uid)
    end

    it 'and can be made sysadmin' do
      user2.remove_role :sysadmin
      visit edit_user_path(user2.id)
      page.check('System admin')
      click_on('Update User')
      visit users_path
      expect(user2.has_role?(:sysadmin)).to eq(true)
    end
  end
end
