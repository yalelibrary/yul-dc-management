# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "PermissionSets", type: :system, prep_metadata_sources: true do
  let(:user) { FactoryBot.create(:user) }
  let(:permission_set) { FactoryBot.create(:permission_set, label: "set 1") }
  let(:permission_set_2) { FactoryBot.create(:permission_set, label: "set 2") }

  before do
    login_as user
  end

  context 'PermissionSets page access' do
    describe 'a regular user' do
      it 'cannot view the Permission Sets link' do
        visit '/'
        expect(page).not_to have_content("Permission Sets")
      end
      it 'cannot visit the Permission Sets route' do
        visit '/permission_sets'
        expect(page).to have_content("Access denied")
      end
    end

    describe 'an approved user' do
      before do
        permission_set.add_approver(user)
      end
      it 'can view the Permission Sets link' do
        visit '/'
        expect(page).to have_content("Permission Sets")
      end
      it 'can view the Permission Sets index' do
        visit '/permission_sets'
        expect(page).to have_content("Permission Sets")
      end
    end

    describe 'an adminsitrator user' do
      before do
        permission_set.add_administrator(user)
      end
      it 'can view the Permission Sets link' do
        visit '/'
        expect(page).to have_content("Permission Sets")
      end
      it 'can view the Permission Sets index' do
        visit '/permission_sets'
        expect(page).to have_content("Permission Sets")
      end
    end

    describe 'a sysadmin user' do
      before do
        user.add_role(:sysadmin)
      end
      it 'can view the Permission Sets link' do
        visit '/'
        expect(page).to have_content("Permission Sets")
      end
      it 'can view the Permission Sets index' do
        visit '/permission_sets'
        expect(page).to have_content("Permission Sets")
      end
    end
  end

  context 'users can only see permission sets they have access to' do
    describe 'approvers roles' do
      before do
        permission_set_2
        permission_set.add_approver(user)
      end
      it 'can only see sets they are approvers for' do
        visit '/permission_sets'
        expect(page).to have_content("Permission Sets")
        expect(page).to have_content("set 1")
        expect(page).not_to have_content("set 2")
      end
    end

    describe 'adminstrator roles' do
      before do
        permission_set
        permission_set_2.add_administrator(user)
      end
      it 'can only see sets they are administrators for' do
        visit '/permission_sets'
        expect(page).to have_content("Permission Sets")
        expect(page).to have_content("set 2")
        expect(page).not_to have_content("set 1")
      end
    end

    describe 'sysadmin roles' do
      before do
        user.add_role(:sysadmin)
        permission_set
        permission_set_2
      end
      it 'can see all of the permission sets' do
        visit '/permission_sets'
        expect(page).to have_content("Permission Sets")
        expect(page).to have_content("set 2")
        expect(page).to have_content("set 1")
      end
    end
  end
end