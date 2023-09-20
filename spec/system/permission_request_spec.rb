# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "PermissionRequests", type: :system, prep_metadata_sources: true do
  let(:sysadmin) { FactoryBot.create(:sysadmin_user) }
  let(:user) { FactoryBot.create(:user) }
  let(:admin_set) { FactoryBot.create(:admin_set) }
  let(:request_user_2) { FactoryBot.create(:permission_request_user, sub: "sub 2", name: "name 2", netid: "net id") }
  let(:permission_set) { FactoryBot.create(:permission_set, label: "set 1") }
  let(:permission_set_2) { FactoryBot.create(:permission_set, label: "set 2") }
  let(:parent_object) { FactoryBot.create(:parent_object) }
  let(:parent_object_2) { FactoryBot.create(:parent_object, oid: "12345", admin_set: admin_set) }
  let(:permission_request) { FactoryBot.create(:permission_request, request_status: true) }
  let(:permission_request_2) { FactoryBot.create(:permission_request, parent_object: parent_object_2, permission_set: permission_set_2, permission_request_user: request_user_2, request_status: true) }
  let(:administrator_user) { FactoryBot.create(:user, uid: 'admin') }
  let(:approver_user) { FactoryBot.create(:user, uid: 'approver') }

  before do
    permission_request
    permission_request_2
    permission_set_2
  end

  context 'as a sysadmin' do
    before do
      login_as sysadmin
    end

    it 'can view a permission request' do
      visit '/'
      expect(page).to have_content("Permission Requests")
      visit '/permission_requests'
      expect(page).to have_content('Permission Requests')
      expect(page).to have_content(permission_request.permission_set.label.to_s)
      expect(page).to have_content(permission_request.created_at.to_s)
      expect(page).to have_content(permission_request.parent_object.oid.to_s)
      expect(page).to have_content(permission_request.permission_request_user.sub.to_s)
      expect(page).to have_content(permission_request.permission_request_user.netid.to_s)
      expect(page).to have_content(permission_request.permission_request_user.name.to_s)
      expect(page).to have_content(permission_request.request_status.to_s)
    end
  end

  context 'as a permission set admin' do
    before do
      login_as administrator_user
      permission_set_2.add_administrator(administrator_user)
    end

    it 'can view a permission request from a set they are an admin for' do
      visit '/'
      expect(page).to have_content("Permission Requests")
      visit '/permission_requests'
      expect(page).to have_content('Permission Requests')
      expect(page).to have_content(permission_request_2.permission_set.label.to_s)
      expect(page).to have_content(permission_request_2.created_at.to_s)
      expect(page).to have_content(permission_request_2.parent_object.oid.to_s)
      expect(page).to have_content(permission_request_2.permission_request_user.sub.to_s)
      expect(page).to have_content(permission_request_2.permission_request_user.name.to_s)
      expect(page).to have_content(permission_request_2.request_status.to_s)

      expect(page).not_to have_content(permission_request.permission_set.label.to_s)
      expect(page).not_to have_content(permission_request.parent_object.oid.to_s)
      expect(page).not_to have_content(permission_request.permission_request_user.sub.to_s)
      expect(page).not_to have_content(permission_request.permission_request_user.netid.to_s)
      expect(page).not_to have_content(permission_request.permission_request_user.name.to_s)
    end
  end

  context 'as a permission set approver' do
    before do
      login_as approver_user
      permission_set_2.add_approver(approver_user)
    end

    it 'can view a permission request from a set they are an admin for' do
      visit '/'
      expect(page).to have_content("Permission Requests")
      visit '/permission_requests'
      expect(page).to have_content('Permission Requests')
      expect(page).to have_content(permission_request_2.permission_set.label.to_s)
      expect(page).to have_content(permission_request_2.created_at.to_s)
      expect(page).to have_content(permission_request_2.parent_object.oid.to_s)
      expect(page).to have_content(permission_request_2.permission_request_user.sub.to_s)
      expect(page).to have_content(permission_request_2.permission_request_user.name.to_s)
      expect(page).to have_content(permission_request_2.permission_request_user.netid.to_s)
      expect(page).to have_content(permission_request_2.request_status.to_s)

      expect(page).not_to have_content(permission_request.permission_set.label.to_s)
      expect(page).not_to have_content(permission_request.parent_object.oid.to_s)
      expect(page).not_to have_content(permission_request.permission_request_user.sub.to_s)
      expect(page).not_to have_content(permission_request.permission_request_user.netid.to_s)
      expect(page).not_to have_content(permission_request.permission_request_user.name.to_s)
    end
  end

  context 'as a regular user' do
    before do
      login_as user
    end
    it 'cannot view or access the Permission Requests page' do
      visit '/'
      expect(page).not_to have_content("Permission Requests")
      visit '/permission_requests'
      expect(page).to have_content("Access denied")
    end
  end
end
