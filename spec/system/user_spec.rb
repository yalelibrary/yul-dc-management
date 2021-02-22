# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'Users', type: :system, js: true do
  let(:user) { FactoryBot.create(:user) }
  let(:user2) { FactoryBot.create(:user, deactivated: true) }
  before do
    login_as user
    visit users_path
  end

  describe 'datatable' do
    it 'defaults to only display Active users' do
      user2.reload
      expect(page).to have_content(user.uid)
      expect(page).to have_no_content(user2.uid)
    end
  end

  describe 'are editable' do
    it 'and require an email to be present' do
      click_on('Edit')
      fill_in('Email', with: '')
      click_on('Update User')

      message = page.find('#user_email').native.attribute('validationMessage')

      expect(message).to eq 'Please fill out this field.'
      expect(current_path).to eq edit_user_path(user.id)
    end
  end
end
