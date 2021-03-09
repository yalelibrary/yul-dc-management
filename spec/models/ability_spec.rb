# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ability, type: :model do
  let(:user) { FactoryBot.create(:user) }
  let(:viewer_user) { FactoryBot.create(:user) }
  let(:sysadmin_user) { FactoryBot.create(:sysadmin_user) }
  let(:metadata_source) { FactoryBot.create(:metadata_source) }
  let(:admin_set) { FactoryBot.create(:admin_set) }
  let(:parent_object) { FactoryBot.create(:parent_object, oid: 16_057_779, authoritative_metadata_source: metadata_source, admin_set: admin_set) }
  let(:child_object) { FactoryBot.create(:child_object, parent_object: parent_object) }
  let(:child_object2) { FactoryBot.create(:child_object, oid: 900_000_000, parent_object: parent_object) }

  describe 'for a sysadmin' do

    it 'grants manage role to User' do
      ability = Ability.new(sysadmin_user)
      assert ability.can?(:manage, User)
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
  end

  describe 'for a user with editor role on an AdminSet' do
    before do
      user.add_role :editor, admin_set
    end

    after do
      user.remove_role :editor, admin_set
    end

    it 'allows edit on a Parent Object' do
      ability = Ability.new(user)
      assert ability.can?(:edit, parent_object)
    end

    it 'allows edit on a Child Object' do
      ability = Ability.new(user)
      assert ability.can?(:edit, child_object)
    end

    it 'allows create on a Parent Object' do
      ability = Ability.new(user)
      assert ability.can?(:create, parent_object)
    end

    it 'allows create on a Child Object' do
      ability = Ability.new(user)
      assert ability.can?(:create, child_object)
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

    it 'disallows edit on a Parent Object' do
      ability = Ability.new(user)
      assert ability.cannot?(:edit, parent_object)
    end

    it 'disallows edit on a Child Object' do
      ability = Ability.new(user)
      assert ability.cannot?(:edit, child_object)
    end

    it 'disallows create on a Parent Object' do
      ability = Ability.new(user)
      assert ability.cannot?(:create, parent_object)
    end

    it 'disallows create on a Child Object' do
      ability = Ability.new(user)
      assert ability.cannot?(:create, child_object)
    end
  end
end
