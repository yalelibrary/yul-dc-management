# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "PermissionSets", type: :system, prep_metadata_sources: true do
  let(:user) { FactoryBot.create(:user) }
  let(:approver_user) { FactoryBot.create(:user) }
  let(:administrator_user) { FactoryBot.create(:user) }
  let(:permission_set) { FactoryBot.create(:permission_set, label: "set 1") }
  let(:permission_set_2) { FactoryBot.create(:permission_set, label: "set 2") }

  before do
    login_as user
    permission_set
    permission_set_2
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
      end
      it 'can see all of the permission sets' do
        visit '/permission_sets'
        expect(page).to have_content("Permission Sets")
        expect(page).to have_content("set 2")
        expect(page).to have_content("set 1")
      end
    end
  end

  context 'permission set showpage' do
    describe 'approvers and administrators' do
      before do
        login_as approver_user
        administrator_user
        permission_set.add_approver(approver_user)
        permission_set_2
      end
      it 'cannot access permission set showpage theyre not approved for' do
        visit "/permission_sets/#{permission_set_2.id}"
        expect(page).to have_content("Access denied")
      end
    end

    describe 'displays permission sets' do
      before do
        user.add_role(:sysadmin)
        permission_set.add_approver(approver_user)
        permission_set.add_administrator(administrator_user)
      end
      it 'metadata' do
        visit "/permission_sets/#{permission_set.id}"
        expect(page).to have_content("set 1")
        expect(page).to have_content("Permission Key")
        expect(page).to have_content("Max Request Queue Length: 1")
      end
      it 'approvers and administrators' do
        visit "/permission_sets/#{permission_set.id}"
        expect(page).to have_content("set 1")
        expect(page).to have_content(approver_user.first_name.to_s)
        expect(page).to have_content(administrator_user.first_name.to_s)
      end
    end
  end
end
