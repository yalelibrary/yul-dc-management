# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PermissionSet, type: :model do
  let(:user) { FactoryBot.create(:user) }
  let(:user2) { FactoryBot.create(:user) }
  let(:permission_set) { FactoryBot.create(:permission_set) }
  let(:permission_set_terms) { FactoryBot.create(:permission_set_term, permission_set: permission_set) }

  describe "user permission set roles" do
    it "adds an approver" do
      expect(user.roles).to be_empty
      permission_set.add_approver(user)
      expect(user.roles.count).to eq(1)
      expect(user.roles.first.name).to eq("approver")
    end

    it "removes an approver" do
      permission_set.add_approver(user)
      expect(user.roles.count).to eq(1)
      permission_set.remove_approver(user)
      expect(user.roles.count).to eq(0)
    end

    it "adds an administrator" do
      expect(user.roles).to be_empty
      permission_set.add_administrator(user)
      expect(user.roles.count).to eq(1)
      expect(user.roles.first.name).to eq("administrator")
    end

    it "removes an administrator" do
      permission_set.add_administrator(user)
      expect(user.roles.count).to eq(1)
      permission_set.remove_administrator(user)
      expect(user.roles.count).to eq(0)
    end

    it "removes an administrator when a approver is added" do
      permission_set.add_administrator(user)
      expect(user.roles.count).to eq(1)
      permission_set.add_approver(user)
      expect(user.roles.count).to eq(1)
      expect(user.roles.first.name).to eq("approver")
    end

    it "removes an approver when an administrator is added" do
      permission_set.add_approver(user)
      expect(user.roles.count).to eq(1)
      permission_set.add_administrator(user)
      expect(user.roles.count).to eq(1)
      expect(user.roles.first.name).to eq("administrator")
    end
  end

  describe "activate_terms!" do
    it "creates and sets the active permission set terms" do
      permission_set.activate_terms!(user, "Test1", "Body1")
      expect(permission_set.active_permission_set_terms.title).to eq "Test1"
      expect(permission_set.active_permission_set_terms.body).to eq "Body1"
    end

    it "deactivates prior active terms" do
      permission_set_terms.activate_by!(user)
      expect(permission_set.active_permission_set_terms).to eq permission_set_terms
      expect(permission_set_terms.inactivated_at).to eq nil
      new_permission_set_terms = permission_set.activate_terms!(user2, "Test1", "Body1")
      expect(permission_set.active_permission_set_terms).to eq new_permission_set_terms
      permission_set_terms.reload
      expect(permission_set_terms.inactivated_at).not_to be nil
      expect(permission_set_terms.inactivated_by).to eq user2
    end
  end

  describe "active_permission_set_terms" do
    it "is nil when there are none" do
      expect(permission_set.active_permission_set_terms).to eq nil
    end

    it "is nil when none are activated" do
      permission_set_terms.activated_at = nil
      permission_set_terms.save!
      permission_set.reload
      expect(permission_set.active_permission_set_terms).to eq nil
    end

    it "is the terms when one is activated" do
      permission_set_terms.activate_by!(user)
      permission_set_terms.save!
      permission_set.reload
      expect(permission_set.active_permission_set_terms).to eq permission_set_terms
    end

    it "is nil after deactivation" do
      permission_set_terms.activate_by!(user)
      permission_set_terms.save!
      permission_set.reload
      expect(permission_set.active_permission_set_terms).to eq permission_set_terms
      permission_set.inactivate_terms_by!(user)
      expect(permission_set.active_permission_set_terms).to eq nil
    end

    it "is nil when they are all inactive" do
      permission_set_terms.activate_by!(user)
      permission_set.reload
      expect(permission_set.active_permission_set_terms).to eq permission_set_terms
      permission_set_terms.inactivate_by!(user)
      permission_set.reload
      expect(permission_set.active_permission_set_terms).to eq nil
    end
  end

  describe PermissionSet do
    it { is_expected.to have_many(:permission_requests) }
  end
end
