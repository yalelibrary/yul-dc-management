# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ability, type: :model, prep_admin_sets: true, prep_metadata_sources: true do
  let(:user) { FactoryBot.create(:user) }
  let(:viewer_user) { FactoryBot.create(:user) }
  let(:sysadmin_user) { FactoryBot.create(:sysadmin_user) }
  let(:metadata_source) { MetadataSource.first }
  let(:admin_set) { FactoryBot.create(:admin_set, key: 'test') }
  let(:parent_object) { FactoryBot.create(:parent_object, oid: 16_057_779, authoritative_metadata_source: metadata_source, admin_set: admin_set) }
  let(:child_object) { FactoryBot.create(:child_object, parent_object: parent_object) }
  let(:child_object2) { FactoryBot.create(:child_object, oid: 900_000_000, parent_object: parent_object) }
  let(:permission_set) { FactoryBot.create(:permission_set) }

  describe 'for a sysadmin' do
    it 'grants manage role to User' do
      ability = Ability.new(sysadmin_user)
      assert ability.can?(:manage, User)
    end

    it 'grants crud roles to Permission Set' do
      ability = Ability.new(sysadmin_user)
      assert ability.can?(:view_list, OpenWithPermission::PermissionSet)
      assert ability.can?(:owp_access, OpenWithPermission::PermissionSet)
      assert ability.can?(:create, OpenWithPermission::PermissionSet)
    end

    it 'grants read access to a ParentObject' do
      ability = Ability.new(sysadmin_user)
      assert ability.can?(:read, parent_object)
    end

    it 'grants read access to a ChildObject' do
      ability = Ability.new(sysadmin_user)
      assert ability.can?(:read, child_object)
    end

    it 'does not grant manage access to a ParentObject' do
      ability = Ability.new(sysadmin_user)
      assert ability.cannot?(:manage, parent_object)
    end

    it 'does not grant manage access to a ChildObject' do
      ability = Ability.new(sysadmin_user)
      assert ability.cannot?(:manage, child_object)
    end

    it 'allows fetching of the parent' do
      ability = Ability.new(sysadmin_user)
      # needed to instantiate the object
      expect(parent_object).to be
      expect(ParentObject.accessible_by(ability).count).to eq(1)
    end

    it 'allows fetching of the children' do
      ability = Ability.new(sysadmin_user)
      # needed to instantiate the object
      expect(parent_object).to be
      expect(child_object).to be
      expect(child_object2).to be
      expect(ChildObject.accessible_by(ability).count).to eq(2)
    end

    context "without editor role" do
      it "disallows add_member on an AdminSet" do
        ability = Ability.new(sysadmin_user)
        assert(ability.cannot?(:add_member, admin_set))
      end
    end

    context "with editor role" do
      before do
        sysadmin_user.add_role(:editor, admin_set)
      end

      it "allows add_member on an AdminSet" do
        ability = Ability.new(sysadmin_user)
        assert(ability.can?(:add_member, admin_set))
      end
    end
  end

  describe 'for a non-sysadmin' do
    it 'does not allow management of Users' do
      ability = Ability.new(user)
      assert ability.cannot?(:manage, User)
    end

    it 'does not allow management of AdminSets' do
      ability = Ability.new(user)
      assert ability.cannot?(:manage, AdminSet)
    end

    it "does not allow add_member on an AdminSet" do
      ability = Ability.new(user)
      assert ability.cannot?(:add_member, admin_set)
    end
  end

  describe 'for a user with viewer role on an AdminSet' do
    before do
      viewer_user.add_role :viewer, admin_set
    end

    after do
      viewer_user.remove_role :viewer, admin_set
    end

    it 'allows read on a Parent Object' do
      ability = Ability.new(viewer_user)
      assert ability.can?(:read, parent_object)
    end

    it 'allows read on a Child Object' do
      ability = Ability.new(viewer_user)
      assert ability.can?(:read, child_object)
    end

    it 'allows fetching of the parent' do
      ability = Ability.new(viewer_user)
      # needed to instantiate the object
      expect(parent_object).to be
      expect(ParentObject.accessible_by(ability).count).to eq(1)
    end

    it 'allows fetching of the children' do
      ability = Ability.new(viewer_user)
      # needed to instantiate the object
      expect(parent_object).to be
      expect(child_object).to be
      expect(child_object2).to be
      expect(ChildObject.accessible_by(ability).count).to eq(2)
    end

    it "disallows add_member on an AdminSet" do
      ability = Ability.new(user)
      assert ability.cannot?(:add_member, admin_set)
    end
  end

  describe 'for a user with editor role on an AdminSet' do
    before do
      user.add_role :editor, admin_set
    end

    after do
      user.remove_role :editor, admin_set
    end

    it 'allows update on a Parent Object' do
      ability = Ability.new(user)
      assert ability.can?(:update, parent_object)
    end

    it 'allows update on a Child Object' do
      ability = Ability.new(user)
      assert ability.can?(:update, child_object)
    end

    it 'allows create on a Parent Object' do
      ability = Ability.new(user)
      assert ability.can?(:create, parent_object)
    end

    it 'allows create on a Child Object' do
      ability = Ability.new(user)
      assert ability.can?(:create, child_object)
    end

    it 'allows destroy on a Parent Object' do
      ability = Ability.new(user)
      assert ability.can?(:destroy, parent_object)
    end

    it 'allows destroy on a Child Object' do
      ability = Ability.new(user)
      assert ability.can?(:destroy, child_object)
    end

    it "allows add_member on an Admin Set" do
      ability = Ability.new(user)
      assert ability.can?(:add_member, admin_set)
    end
  end

  describe 'for a user without roles on an AdminSet' do
    it 'disallows read on a Parent Object' do
      ability = Ability.new(user)
      assert ability.cannot?(:read, parent_object)
    end

    it 'disallows read on a Child Object' do
      ability = Ability.new(user)
      assert ability.cannot?(:read, child_object)
    end

    it 'disallows update on a Parent Object' do
      ability = Ability.new(user)
      assert ability.cannot?(:update, parent_object)
    end

    it 'disallows update on a Child Object' do
      ability = Ability.new(user)
      assert ability.cannot?(:update, child_object)
    end

    it 'disallows create on a Parent Object' do
      ability = Ability.new(user)
      assert ability.cannot?(:create, parent_object)
    end

    it 'disallows create on a Child Object' do
      ability = Ability.new(user)
      assert ability.cannot?(:create, child_object)
    end

    it 'disallows destroy on a Parent Object' do
      ability = Ability.new(user)
      assert ability.cannot?(:destroy, parent_object)
    end

    it 'disallows destroy on a Child Object' do
      ability = Ability.new(user)
      assert ability.cannot?(:destroy, child_object)
    end

    it "disallows allow add_member on an Admin Set" do
      ability = Ability.new(user)
      assert ability.cannot?(:add_member, admin_set)
    end
  end

  describe 'for an approver on Permission Sets' do
    before do
      user.add_role :approver, permission_set
    end
    it 'allows approver to read Permission Set' do
      ability = Ability.new(user)
      assert ability.can?(:read, permission_set)
    end
    it 'does not allow approver to crud Permission Set' do
      ability = Ability.new(user)
      assert ability.cannot?(:crud, permission_set)
    end
  end

  describe 'for an administrator on Permission Sets' do
    before do
      user.add_role :administrator, permission_set
    end
    it 'allows administrator to crud Permission Set' do
      ability = Ability.new(user)
      assert ability.can?(:read, permission_set)
      assert ability.can?(:update, permission_set)
    end
  end
end
