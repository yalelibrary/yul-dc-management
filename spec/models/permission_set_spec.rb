# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PermissionSet, type: :model do
  let(:user) { FactoryBot.create(:user) }
  let(:permission_set) { FactoryBot.create(:permission_set) }

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

  describe PermissionSet do
    it { is_expected.to have_many(:permission_requests) }
  end
end
