# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "PermissionRequests", type: :system, prep_metadata_sources: true, js: true do
  let(:sysadmin) { FactoryBot.create(:sysadmin_user) }
  let(:user) { FactoryBot.create(:user) }
  let(:admin_set) { FactoryBot.create(:admin_set) }
  let(:request_user) { FactoryBot.create(:permission_request_user, sub: "sub 1", name: "name 1", netid: "netid") }
  let(:request_user_two) { FactoryBot.create(:permission_request_user, sub: "sub 2", name: "name 2", netid: "net id") }
  let(:permission_set) { FactoryBot.create(:permission_set, label: "set 1", key: 'key 1') }
  let(:permission_set_two) { FactoryBot.create(:permission_set, label: "set 2", key: 'key 2') }
  let(:parent_object) { FactoryBot.create(:parent_object, oid: "2002826", admin_set_id: admin_set.id) }
  let(:parent_object_two) { FactoryBot.create(:parent_object, oid: "2005512", admin_set_id: admin_set.id) }
  # rubocop:disable Layout/LineLength
  let(:permission_request) do
    FactoryBot.create(:permission_request, request_status: "Approved", permission_set: permission_set, parent_object: parent_object, permission_request_user: request_user, user_note: 'something', permission_request_user_name: 'name 2')
  end
  let(:permission_request_two) do
    FactoryBot.create(:permission_request, parent_object: parent_object_two, permission_set: permission_set_two, permission_request_user: request_user_two, request_status: "Approved", permission_request_user_name: 'name 3')
  end
  # rubocop:enable Layout/LineLength
  let(:administrator_user) { FactoryBot.create(:user, uid: 'admin') }
  let(:approver_user) { FactoryBot.create(:user, uid: 'approver') }

  before do
    stub_ptiffs_and_manifests
    stub_metadata_cloud('2034600')
    stub_metadata_cloud('2005512')
    parent_object
    parent_object_two
    permission_request
    permission_request_two
  end

  describe 'index' do
    context 'as a sysadmin' do
      before do
        login_as sysadmin
      end

      it 'can view all permission requests' do
        visit '/'
        expect(page).to have_content('PERMISSION REQUESTS')
        visit '/permission_requests'
        expect(page).to have_content('All Matching Entries')
        expect(page).to have_content(permission_request.created_at.to_s)
        expect(page).to have_content(permission_request.permission_set.label.to_s)
        expect(page).to have_content(permission_request.parent_object.oid.to_s)
        expect(page).to have_content(permission_request.permission_request_user.sub.to_s)
        expect(page).to have_content(permission_request.permission_request_user_name.to_s)
        expect(page).to have_content(permission_request.request_status.to_s)
        expect(page).to have_content(permission_request_two.permission_set.label.to_s)
        expect(page).to have_content(permission_request_two.created_at.to_s)
        expect(page).to have_content(permission_request_two.parent_object.oid.to_s)
        expect(page).to have_content(permission_request_two.permission_request_user.sub.to_s)
        expect(page).to have_content(permission_request_two.permission_request_user.name.to_s)
        expect(page).to have_content(permission_request_two.request_status.to_s)
      end
    end

    context 'as a permission set admin' do
      before do
        permission_set_two.add_administrator(administrator_user)
        login_as administrator_user
      end

      it 'can view a permission request from a set they are an admin for' do
        visit '/'
        expect(page).to have_content("PERMISSION REQUESTS")
        visit '/permission_requests'
        expect(page).to have_content('All Matching Entries')
        expect(page).to have_content(permission_request_two.permission_set.label.to_s)
        expect(page).to have_content(permission_request_two.created_at.to_s)
        expect(page).to have_content(permission_request_two.parent_object.oid.to_s)
        expect(page).to have_content(permission_request_two.permission_request_user.sub.to_s)
        expect(page).to have_content(permission_request_two.permission_request_user_name.to_s)
        expect(page).to have_content(permission_request_two.request_status.to_s)

        expect(page).not_to have_content(permission_request.parent_object.oid.to_s)
        expect(page).not_to have_content(permission_request.permission_request_user.sub.to_s)
        expect(page).not_to have_content(permission_request.permission_request_user.name.to_s)
      end
    end

    context 'as a permission set approver' do
      before do
        permission_set_two.add_approver(approver_user)
        login_as approver_user
      end

      it 'can view a permission request from a set they are an approver for' do
        visit '/'
        expect(page).to have_content("PERMISSION REQUESTS")
        visit '/permission_requests'
        expect(page).to have_content('All Matching Entries')
        expect(page).to have_content(permission_request_two.permission_set.label.to_s)
        expect(page).to have_content(permission_request_two.created_at.to_s)
        expect(page).to have_content(permission_request_two.parent_object.oid.to_s)
        expect(page).to have_content(permission_request_two.permission_request_user.sub.to_s)
        expect(page).to have_content(permission_request_two.permission_request_user_name.to_s)
        expect(page).to have_content(permission_request_two.request_status.to_s)

        expect(page).not_to have_content(permission_request.parent_object.oid.to_s)
        expect(page).not_to have_content(permission_request.permission_request_user.sub.to_s)
        expect(page).not_to have_content(permission_request.permission_request_user.name.to_s)
      end
    end

    context 'as a regular user' do
      before do
        login_as user
      end

      it 'cannot view or access the Permission Requests page' do
        visit '/'
        expect(page).not_to have_content("PERMISSION REQUESTS")
        visit '/permission_requests'
        expect(page).to have_content("Access denied")
      end
    end
  end

  describe 'show' do
    context 'as a sysadmin' do
      before do
        login_as sysadmin
      end

      it 'can view a permission request' do
        visit "/permission_requests/#{permission_request.id}"
        expect(page).to have_content('Permission Request')
        expect(page).to have_content(permission_request.id.to_s)
        expect(page).to have_content(permission_request.permission_set.label.to_s)
        expect(page).to have_content(permission_request.created_at.to_s)
        expect(page).to have_content(permission_request.parent_object.oid.to_s)
        expect(page).to have_content(permission_request.permission_request_user.sub.to_s)
        expect(page).to have_content(permission_request.permission_request_user.name.to_s)
        expect(page).to have_content(permission_request.user_note.to_s)
      end

      it 'can approve or deny a permission request' do
        expect(permission_request.request_status).to eq "Approved"
        visit "/permission_requests/#{permission_request.id}"
        find('#open_with_permission_permission_request_request_status_denied').click
        click_on 'Save'
        permission_request.reload
        expect(permission_request.request_status).to eq "Denied"
        visit "/permission_requests/#{permission_request.id}"
        find('#open_with_permission_permission_request_request_status_approved').click
        click_on 'Save'
        permission_request.reload
        expect(permission_request.request_status).to eq "Approved"
      end

      it 'can request a change in access type' do
        visit "/permission_requests/#{permission_request.id}"
        find('#open_with_permission_permission_request_change_access_type_yes').click
        find('#open_with_permission_permission_request_new_visibility_public').click
        expect do
          click_on 'Save'
        end.to change { ActionMailer::Base.deliveries.count }.by(1)
      end
    end

    context 'as a permission set admin' do
      before do
        permission_set.add_administrator(administrator_user)
        login_as administrator_user
      end

      it 'can view a permission request from a set they are an admin for' do
        visit "/permission_requests/#{permission_request.id}"
        expect(page).to have_content('Permission Request')
        expect(page).to have_content(permission_request.id.to_s)
        expect(page).to have_content(permission_request.permission_set.label.to_s)
        expect(page).to have_content(permission_request.created_at.to_s)
        expect(page).to have_content(permission_request.parent_object.oid.to_s)
        expect(page).to have_content(permission_request.permission_request_user.sub.to_s)
        expect(page).to have_content(permission_request.permission_request_user.name.to_s)
        expect(page).to have_content(permission_request.user_note.to_s)
      end

      it 'can approve or deny a permission request' do
        expect(permission_request.request_status).to eq "Approved"
        visit "/permission_requests/#{permission_request.id}"
        find('#open_with_permission_permission_request_request_status_denied').click
        click_on 'Save'
        permission_request.reload
        expect(permission_request.request_status).to eq "Denied"
        visit "/permission_requests/#{permission_request.id}"
        find('#open_with_permission_permission_request_request_status_approved').click
        click_on 'Save'
        permission_request.reload
        expect(permission_request.request_status).to eq "Approved"
      end

      it 'can request a change in access type' do
        visit "/permission_requests/#{permission_request.id}"
        find('#open_with_permission_permission_request_change_access_type_yes').click
        find('#open_with_permission_permission_request_new_visibility_public').click
        expect do
          click_on 'Save'
        end.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      it 'cannot view, approve, or deny a permission request from a set they are not an admin or approver for' do
        visit "/permission_requests/#{permission_request_two.id}"
        expect(page).to have_content('Access denied')
      end
    end

    context 'as a permission set approver' do
      before do
        permission_set_two.add_approver(approver_user)
        login_as approver_user
      end

      it 'can view a permission request from a set they are an approver for' do
        visit "/permission_requests/#{permission_request_two.id}"
        expect(page).to have_content('Permission Request')
        expect(page).to have_content(permission_request_two.id.to_s)
        expect(page).to have_content(permission_request_two.permission_set.label.to_s)
        expect(page).to have_content(permission_request_two.created_at.to_s)
        expect(page).to have_content(permission_request_two.parent_object.oid.to_s)
        expect(page).to have_content(permission_request_two.permission_request_user.sub.to_s)
        expect(page).to have_content(permission_request_two.permission_request_user.name.to_s)
        expect(page).to have_content(permission_request_two.user_note.to_s)
      end

      it 'can approve or deny a permission request from a set they are an approver for' do
        expect(permission_request_two.request_status).to eq "Approved"
        visit "/permission_requests/#{permission_request_two.id}"
        find('#open_with_permission_permission_request_request_status_denied').click
        click_on 'Save'
        permission_request_two.reload
        expect(permission_request_two.request_status).to eq "Denied"
        find('#open_with_permission_permission_request_request_status_approved').click
        click_on 'Save'
        permission_request_two.reload
        expect(permission_request_two.request_status).to eq "Approved"
      end

      it 'can request a change in access type' do
        visit "/permission_requests/#{permission_request_two.id}"
        find('#open_with_permission_permission_request_change_access_type_yes').click
        find('#open_with_permission_permission_request_new_visibility_public').click
        expect do
          click_on 'Save'
        end.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      it 'cannot view, approve, or deny a permission request from a set they are not an admin or approver for' do
        visit "/permission_requests/#{permission_request.id}"
        expect(page).to have_content('Access denied')
      end
    end

    context 'as a regular user' do
      before do
        login_as user
      end

      it 'cannot view, approve, or deny a permission request from a set they are not an admin or approver for' do
        visit "/permission_requests/#{permission_request.id}"
        expect(page).to have_content('Access denied')
      end
    end
  end
end
