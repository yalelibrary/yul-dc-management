# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'Users', type: :system, js: true do
  let(:user) { FactoryBot.create(:user, uid: 'mbl52342') }
  let(:user2) { FactoryBot.create(:user, uid: 'abl52342') }
  let(:user3) { FactoryBot.create(:user, uid: 'gbl52342', deactivated: true) }

  before do
    user.sysadmin = true
    login_as user
  end

  describe 'datatable' do
    before do
      user2.reload
      user3.reload
      visit users_path
    end

    it 'defaults to only display Active users' do
      expect(page).to have_content(user.uid)
      expect(page).to have_content(user2.uid)
      expect(page).not_to have_content(user3.uid)
    end

    it 'defaults to ascending order' do
      active_sorted_users = User.where(deactivated: false).pluck(:uid).sort
      ordered_users_in_datatable = []

      expect(page).to have_content(user.uid) # add expect to make sure page is loaded before page.all()
      page.all('#users-datatable tbody tr').each do |tr|
        ordered_users_in_datatable << tr.text.split(" ").first
      end

      expect(ordered_users_in_datatable).to eq(active_sorted_users)
    end

    it 'filters by netid' do
      active_sorted_users_name_starting_with_m = User.where(deactivated: false).where("uid like 'm%'").pluck(:uid).sort
      active_users_without_name_starting_with_m = User.where(deactivated: false).where("not uid like 'm%'").pluck(:uid).sort
      ordered_users_in_datatable = []

      expect(page).to have_content(user.uid) # add expect to make sure page is loaded before page.all()
      fill_in("NetID", with: "m")
      expect(page).not_to have_content(active_users_without_name_starting_with_m[0]) if active_users_without_name_starting_with_m.count > 0
      expect(page).to have_content(active_sorted_users_name_starting_with_m[0]) if active_sorted_users_name_starting_with_m.count > 0
      page.all('#users-datatable tbody tr').each do |tr|
        ordered_users_in_datatable << tr.text.split(" ").first
      end

      expect(ordered_users_in_datatable).to eq(active_sorted_users_name_starting_with_m)
    end
  end

  describe 'are viewable' do
    let(:admin_set) { FactoryBot.create(:admin_set) }

    before do
      user.add_role(:editor, admin_set)
      visit users_path
      click_on(user.uid.to_s)
    end

    it 'displays the users roles' do
      expect(page).to have_content('User Details')

      within('table', text: 'Admin Set') do
        expect(page).to have_css('td', text: admin_set.label.to_s)
        expect(page).to have_css('td', text: "editor")
      end
    end
  end

  describe 'are editable' do
    it 'and require an email to be present' do
      visit users_path
      page.find(:css, 'svg.fa-pencil').click
      expect(page).to have_content('Email')
      fill_in('Email', with: '')
      click_on('Update User')

      message = page.find('#user_email').native.attribute('validationMessage')

      expect(message).to eq 'Please fill out this field.'
      expect(current_path).to eq edit_user_path(user.id)
    end

    it 'and require their full name to be present' do
      visit users_path
      page.find(:css, 'svg.fa-pencil').click
      expect(page).to have_content('First name')
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
