# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::PermissionRequest, type: :model, prep_metadata_sources: true, prep_admin_sets: true do
  let(:user) { FactoryBot.create(:user) }
  let(:admin_set) { FactoryBot.create(:admin_set) }
  let(:request_user) { FactoryBot.create(:permission_request_user) }
  let(:permission_set) { FactoryBot.create(:permission_set, label: "set 1") }
  let(:parent_object) { FactoryBot.create(:parent_object, admin_set: admin_set) }
  let(:approver_user) { FactoryBot.create(:user, uid: 'approver') }

  describe 'with valid attributes' do
    it 'is valid' do
      expect(Api::PermissionRequest.new(permission_set_id: permission_set,
                                        permission_request_user_id: request_user,
                                        parent_object_id: parent_object,
                                        user_id: approver_user,
                                        user_note: "Note")).to be_valid
    end

    it 'has the expected fields' do
      u = described_class.new
      u.parent_object_id = parent_object.id
      u.permission_set_id = permission_set.id
      u.permission_request_user_id = request_user.id
      u.user_id = user.id
      u.user_note = "Note"
      u.save!

      expect(u.errors).to be_empty
      expect(u.parent_object_id).to eq parent_object.id
      expect(u.permission_set_id).to eq permission_set.id
      expect(u.permission_request_user_id).to eq request_user.id
      expect(u.user_id).to eq user.id
      expect(u.user_note).to eq "Note"
      expect(u.request_status).to eq nil
    end
  end
end
