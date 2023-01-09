# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'PermissionSets', type: :system, prep_metadata_sources: true do
  let(:user) { FactoryBot.create(:user) }
  let(:user_2) { FactoryBot.create(:user) }
  let(:approver_user) { FactoryBot.create(:user) }
  let(:administrator_user) { FactoryBot.create(:user, uid: 'admin') }
  let(:permission_set) { FactoryBot.create(:permission_set, label: 'set 1') }
  let(:permission_set_2) { FactoryBot.create(:permission_set, label: 'set 2') }
  let(:edit_set) { 'Editing Permission Set' }
  let(:new_set) { 'New Permission Set' }
  let(:create_set) { 'Create Permission Set' }
  let(:sets) { 'Permission Sets' }
  let(:denied) { 'Access denied' }
  let(:create_new_set) { 'Create New Permission Set' }
  let(:new_set_url) { '/permission_sets/new' }

  before do
    login_as user
    permission_set
    permission_set_2
  end

  context 'PermissionSets page access' do
    describe 'a regular user' do
      it 'cannot view the Permission Sets link' do
        visit '/'
        expect(page).not_to have_content(sets)
      end
      it 'cannot visit the Permission Sets route' do
        visit '/permission_sets'
        expect(page).to have_content(denied)
      end
    end

    describe 'an approved user' do
      before do
        permission_set.add_approver(user)
      end
      it 'can view the Permission Sets link' do
        visit '/'
        expect(page).to have_content(sets)
      end
      it 'can view the Permission Sets index' do
        visit '/permission_sets'
        expect(page).to have_content(sets)
      end
    end

    describe 'an adminsitrator user' do
      before do
        permission_set.add_administrator(user)
      end
      it 'can view the Permission Sets link' do
        visit '/'
        expect(page).to have_content(sets)
      end
      it 'can view the Permission Sets index' do
        visit '/permission_sets'
        expect(page).to have_content(sets)
      end
    end

    describe 'a sysadmin user' do
      before do
        user.add_role(:sysadmin)
      end
      it 'can view the Permission Sets link' do
        visit '/'
        expect(page).to have_content(sets)
      end
      it 'can view the Permission Sets index' do
        visit '/permission_sets'
        expect(page).to have_content(sets)
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
        expect(page).to have_content(sets)
        expect(page).to have_content('set 1')
        expect(page).not_to have_content('set 2')
      end
    end

    describe 'adminstrator roles' do
      before do
        permission_set_2.add_administrator(user)
      end
      it 'can only see sets they are administrators for' do
        visit '/permission_sets'
        expect(page).to have_content(sets)
        expect(page).to have_content('set 2')
        expect(page).not_to have_content('set 1')
      end
    end

    describe 'sysadmin roles' do
      before do
        user.add_role(:sysadmin)
      end
      it 'can see all of the permission sets' do
        visit '/permission_sets'
        expect(page).to have_content(sets)
        expect(page).to have_content('set 2')
        expect(page).to have_content('set 1')
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
        expect(page).to have_content(denied)
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
        expect(page).to have_content('set 1')
        expect(page).to have_content('Permission Key')
        expect(page).to have_content('Max Request Queue Length: 1')
      end
      it 'approvers and administrators' do
        visit "/permission_sets/#{permission_set.id}"
        expect(page).to have_content('set 1')
        expect(page).to have_content(approver_user.first_name.to_s)
        expect(page).to have_content(administrator_user.first_name.to_s)
      end
    end
  end

  context 'Editing and creating Permission Sets' do
    describe 'editing, creating, and adding/removing user roles to permission sets as a sysadmin' do
      before do
        user_2
        user.add_role(:sysadmin)
      end
      it 'can be viewed' do
        visit '/permission_sets'
        expect(page).to have_content(create_new_set)
        expect(page).to have_link('Edit', count: 2)
        expect(page).to have_content('Edit', count: 3)
      end
      it 'can be accessed' do
        visit "/permission_sets/#{permission_set.id}/edit"
        expect(page).to have_content(edit_set)
      end
      it 'can be edited' do
        visit "/permission_sets/#{permission_set.id}/edit"
        fill_in('permission_set_key', with: 'key example')
        fill_in('permission_set_label', with: 'label example')
        click_on 'Update Permission Set'
        expect(page).to have_content('Permission set was successfully updated.')
      end
      it 'can reject invalid params' do
        visit "/permission_sets/#{permission_set.id}/edit"
        fill_in('permission_set_key', with: 'key example')
        # permission set must also have label - this leaves that out making the request invalid and causing a render of the edit page
        fill_in('permission_set_label', with: '')
        click_on 'Update Permission Set'
        expect(page).to have_content(edit_set)
      end
      it 'can be created' do
        visit new_set_url
        expect(page).to have_content(new_set)
        fill_in('permission_set_key', with: 'key example')
        fill_in('permission_set_label', with: 'label example')
        fill_in('permission_set_max_queue_length', with: '10')
        click_on create_set
        expect(page).to have_content('Permission set was successfully created.')
        expect(page).to have_content('key example')
        expect(page).to have_content('label example')
      end
      it 'can reject invalid params upon creation' do
        visit new_set_url
        expect(page).to have_content(new_set)
        fill_in('permission_set_key', with: 'key example')
        # permission set must also have label - this leaves that out making the request invalid and causing a render of the new page
        fill_in('permission_set_label', with: '')
        fill_in('permission_set_max_queue_length', with: '10')
        click_on create_set
        expect(page).to have_content(new_set)
      end
      it 'can add and remove user roles to permission set' do
        visit "/permission_sets/#{permission_set.id}/"
        fill_in('uid', with: user_2.uid.to_s)
        click_on 'Save'
        expect(page).to have_content("User: #{user_2.uid} added as approver")
        all('a', text: 'X')[0].click
        expect(page).to have_content("User: #{user_2.uid} removed as approver")
      end
    end

    describe 'editing, creating, and adding/removing user roles to permission sets as an administrator' do
      before do
        login_as administrator_user
        user
        permission_set.add_administrator(administrator_user)
      end
      it 'can be viewed' do
        visit '/permission_sets'
        expect(page).to have_content(create_new_set)
        expect(page).to have_link('Edit')
        expect(page).to have_content('Edit').twice
      end
      it 'can be accessed' do
        visit "/permission_sets/#{permission_set.id}/edit"
        expect(page).to have_content(edit_set)
      end
      it 'can add and remove user roles to permission set' do
        visit "/permission_sets/#{permission_set.id}/"
        fill_in('uid', with: user.uid.to_s)
        click_on 'Save'
        expect(page).to have_content("User: #{user.uid} added as approver")
        all('a', text: 'X')[0].click
        expect(page).to have_content("User: #{user.uid} removed as approver")
      end
      it 'can be created' do
        visit new_set_url
        expect(page).to have_content(new_set)
        fill_in('permission_set_key', with: 'key example')
        fill_in('permission_set_label', with: 'label example')
        fill_in('permission_set_max_queue_length', with: '10')
        click_on create_set
        expect(page).to have_content('Permission set was successfully created.')
        expect(page).to have_content('key example')
        expect(page).to have_content('label example')
      end
    end

    describe 'editing and creating permission sets as an approver' do
      before do
        administrator_user
        login_as approver_user
        permission_set.add_approver(approver_user)
        permission_set.add_administrator(administrator_user)
      end
      it 'cannot be viewed' do
        visit '/permission_sets'
        expect(page).not_to have_content(create_new_set)
        expect(page).not_to have_link('Edit')
      end
      it 'cannot remove or add users from a permission set' do
        visit "/permission_sets/#{permission_set.id}"
        expect(page).to have_content('(admin)')
        expect(page).not_to have_link('X')
        expect(page).not_to have_content('NetID')
        expect(page).not_to have_content('Save')
      end
      it 'cannot be accessed' do
        visit "/permission_sets/#{permission_set.id}/edit"
        expect(page).to have_content(denied)
      end
      it 'cannot be created' do
        visit new_set_url
        expect(page).to have_content(denied)
      end
    end
  end
end
