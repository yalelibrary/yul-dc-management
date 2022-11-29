# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PermissionRequest, type: :model, prep_metadata_sources: true, prep_admin_sets: true do
  let(:user) { FactoryBot.create(:user) }
  let(:admin_set) { FactoryBot.create(:admin_set) }
  let(:request_user) { FactoryBot.create(:permission_request_user) }
  let(:permission_set) { FactoryBot.create(:permission_set, label: "set 1") }
  let(:parent_object) { FactoryBot.create(:parent_object, admin_set: admin_set) }
  let(:approver_user) { FactoryBot.create(:user, uid: 'approver') }

  before do
    permission_set
  end

  describe 'with valid attributes' do
    it 'is valid' do
      expect(PermissionRequest.new(permission_set: permission_set, permission_request_user: request_user, parent_object: parent_object, user: approver_user, user_note: "Note")).to be_valid
    end

    it 'has the expected fields' do
      u = described_class.new
      u.parent_object = parent_object
      u.permission_set = permission_set
      u.permission_request_user = request_user
      u.user = user
      u.user_note = "Note"
      u.save!

      expect(u.errors).to be_empty
      expect(u.parent_object).to eq parent_object
      expect(u.permission_set).to eq permission_set
      expect(u.permission_request_user).to eq request_user
      expect(u.user).to eq user
      expect(u.user_note).to eq "Note"
    end
  end
end