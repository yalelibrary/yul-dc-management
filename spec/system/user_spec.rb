# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'Users', type: :system, js: true do
  let(:user) { FactoryBot.create(:user) }
  let(:user2) { FactoryBot.create(:user) }

  before do
    user.sysadmin = true
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
      user2.sysadmin = false
      visit edit_user_path(user2.id)
      page.check('System admin')
      click_on('Update User')
      visit users_path
      expect(user2.sysadmin).to eq(true)
    end
  end

  describe 'created' do
    it 'with valid user succeeds' do
      visit users_path
      click_on('New User')
      expect(page).to have_content('Create User')
      fill_in('Uid', with: 'testuid')
      fill_in('First name', with: 'Teddy')
      fill_in('Last name', with: 'Testerly')
      fill_in('Email', with: 'tt@testerly.com')
      click_on('Create User')
      expect(page).to have_content('User was successfully created')
      expect(page).to have_content('Teddy')
    end
  end

  it 'with invalid properties provides feedback' do
    visit users_path
    click_on('New User')
    expect(page).to have_content('Create User')
    fill_in('Uid', with: 'testuid')
    fill_in('First name', with: 'Teddy')
    fill_in('Last name', with: '')
    fill_in('Email', with: 'tt@testerly.com')
    click_on('Create User')
    message = page.find('#user_last_name').native.attribute('validationMessage')
    expect(message).to eq 'Please fill out this field.'
    expect(current_path).to eq new_user_path
  end
end
