# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'PermissionSets', type: :system, prep_metadata_sources: true, js: true do
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
  let(:permission_set_terms_element) { ".permission-set-terms" }
  let(:active_version_element) { ".active-version" }
  let(:test_title) { "Test Title" }
  let(:test_body) { "Test Body" }

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
      it 'can be manage terms' do
        visit "/permission_sets/#{permission_set.id}/permission_set_terms"
        expect(page).to have_content("Terms and Conditions for #{permission_set.label}")
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
        expect(page).not_to have_content('Manage Terms and Conditions')
      end
      it 'cannot be accessed' do
        visit "/permission_sets/#{permission_set.id}/edit"
        expect(page).to have_content(denied)
      end
      it 'cannot manage terms' do
        visit permission_set_terms_permission_set_url(permission_set)
        expect(page).to have_content(denied)
      end
      it 'cannot be created' do
        visit new_set_url
        expect(page).to have_content(denied)
      end
    end
  end

  describe 'active permission set terms' do
    before do
      administrator_user
      login_as approver_user
      permission_set.add_approver(approver_user)
      permission_set.add_administrator(administrator_user)
    end

    context 'when there are active terms' do
      let(:terms) { permission_set.activate_terms!(administrator_user, test_title, test_body) }

      before do
        terms # activate some terms
      end

      it "index displays activation date an user" do
        visit "/permission_sets"
        expect(page).to have_content(sets)
        within(permission_set_terms_element) do
          expect(page).to have_content(terms.activated_at.to_s)
          expect(page).to have_content(administrator_user.uid.to_s)
        end
      end

      it "index displays None if terms are inactivated" do
        permission_set.inactivate_terms_by!(administrator_user)
        visit "/permission_sets"
        expect(page).to have_content(sets)
        within(permission_set_terms_element) do
          expect(page).to have_content("None")
          expect(page).not_to have_content(terms.activated_at.to_s)
          expect(page).not_to have_content(administrator_user.uid.to_s)
        end
      end

      it "show page displays activation date and user" do
        visit "/permission_sets/#{permission_set.id}"
        expect(page).to have_content(permission_set.label)
        within(permission_set_terms_element) do
          expect(page).to have_content(terms.activated_at.to_s)
          expect(page).to have_content(terms.title.to_s)
        end
      end

      it "show page displays None when terms are inactivated" do
        permission_set.inactivate_terms_by!(administrator_user)
        visit "/permission_sets/#{permission_set.id}"
        expect(page).to have_content(permission_set.label)
        within(permission_set_terms_element) do
          expect(page).to have_content("None")
          expect(page).not_to have_content(terms.activated_at.to_s)
          expect(page).not_to have_content(terms.title.to_s)
        end
      end

      describe "terms page" do
        before do
          login_as administrator_user
        end

        it "terms page displays active term" do
          visit permission_set_terms_permission_set_url(permission_set)
          expect(page).to have_content(permission_set.label)
          within(active_version_element) do
            expect(page).to have_content(terms.activated_at.to_s)
          end
        end

        it "terms page displays None when terms are inactivated" do
          permission_set.inactivate_terms_by!(administrator_user)
          visit permission_set_terms_permission_set_url(permission_set)
          expect(page).to have_content(permission_set.label)
          within(active_version_element) do
            expect(page).to have_content("None")
            expect(page).not_to have_content(terms.activated_at.to_s)
          end
        end

        it "terms page displays Remove button" do
          visit permission_set_terms_permission_set_url(permission_set)
          expect(page).to have_content("Remove")
        end

        it "terms page does not display Remove button when inactivated" do
          permission_set.inactivate_terms_by!(administrator_user)
          visit permission_set_terms_permission_set_url(permission_set)
          expect(page).not_to have_content("Remove")
        end
      end
    end

    context 'when there are no terms' do
      it "index displays None" do
        visit "/permission_sets"
        expect(page).to have_content(sets)
        within(permission_set_terms_element) do
          expect(page).to have_content("None")
        end
      end

      it "show page displays None" do
        visit "/permission_sets/#{permission_set.id}"
        expect(page).to have_content("Key: Permission Key")
        within(permission_set_terms_element) do
          expect(page).to have_content("None")
        end
      end

      it "terms page does not display Remove button" do
        permission_set.inactivate_terms_by!(administrator_user)
        visit permission_set_terms_permission_set_url(permission_set)
        expect(page).not_to have_content("Remove")
      end

      it "can create a new term from form" do
        login_as administrator_user
        permission_set.add_administrator(administrator_user)
        visit "permission_sets/#{permission_set.id}/new_term"
        expect(page).to have_content("Terms and Conditions for #{permission_set.label}")
        fill_in('Title', with: "Title")
        fill_in('Body', with: "Body")
        click_on "Create Terms and Conditions"
        expect(page.driver.browser.switch_to.alert.text).to eq("Create new Terms and Conditions? Users will be required to agree to these terms.")
        page.driver.browser.switch_to.alert.accept
        expect(page).to have_content("ACTIVE")
        visit "permission_sets/#{permission_set.id}/new_term"
        fill_in('Title', with: "Title")
        fill_in('Body', with: "Body")
        click_on "Create Terms and Conditions"
        expect(page.driver.browser.switch_to.alert.text).to eq("Create new Terms and Conditions? This will replace the existing terms.")
      end

      it "cannot create a new term if not an administrator" do
        login_as user
        visit "permission_sets/#{permission_set.id}/new_term"
        expect(page).to have_content("Access denied")
      end
    end
  end
end
