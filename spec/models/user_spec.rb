# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { FactoryBot.create(:user) }
  let(:admin_set) { FactoryBot.create(:admin_set) }
  let(:permission_set) { FactoryBot.create(:permission_set) }

  it "has the expected fields" do
    u = described_class.new
    u.email = "river@yale.edu"
    u.provider = "cas"
    u.first_name = 'River'
    u.last_name = 'Dale'
    u.uid = "River"
    u.save!

    expect(u.errors).to be_empty
    expect(u.provider).to eq "cas"
    expect(u.uid).to eq "River"
    expect(u.first_name).to eq 'River'
    expect(u.last_name).to eq 'Dale'
  end

  describe 'deactivate!' do
    it 'deactivates a user and removes all roles' do
      user.add_role :sysadmin
      user.add_role :viewer, admin_set
      user.add_role :editor, admin_set
      user.add_role :administrator, permission_set
      user.add_role :approver, permission_set
      expect(user.deactivated).to eq(false)
      user.deactivate!
      expect(user.deactivated).to eq(true)
      expect(user.has_role?(:sysadmin)).to eq(false)
      expect(user.has_role?(:editor, admin_set)).to eq(false)
      expect(user.has_role?(:viewer, admin_set)).to eq(false)
      expect(user.has_role?(:administrator, permission_set)).to eq(false)
      expect(user.has_role?(:approver, permission_set)).to eq(false)
    end
  end

  describe 'sysadmin property' do
    it 'adds the sysadmin role when set to true' do
      user.remove_role :sysadmin
      user.sysadmin = true
      expect(user.has_role?(:sysadmin)).to eq(true)
    end
    it 'removes the sysadmin role when set to false' do
      user.add_role :sysadmin
      user.sysadmin = false
      expect(user.has_role?(:sysadmin)).to eq(false)
    end
    it 'removes the sysadmin role when set to 0' do
      user.add_role :sysadmin
      user.sysadmin = '0'
      expect(user.has_role?(:sysadmin)).to eq(false)
    end
  end

  describe 'with validations' do
    it 'verifies that a new user has an email' do
      user2 = described_class.new(email: nil)
      expect(user2).not_to be_valid
      expect(user2.errors.messages[:email]).to eq ["can't be blank"]
    end

    it 'verifies that a new user has a first and last name' do
      user2 = described_class.new(first_name: nil, last_name: nil)
      expect(user2).not_to be_valid
      expect(user2.errors.messages[:first_name]).to eq ["can't be blank"]
      expect(user2.errors.messages[:last_name]).to eq ["can't be blank"]
    end
  end

  describe User do
    it { is_expected.to have_many(:permission_requests) }
  end
end
