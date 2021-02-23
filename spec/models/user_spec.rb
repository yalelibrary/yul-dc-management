# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { FactoryBot.create(:user) }

  it "has the expected fields" do
    u = described_class.new
    u.email = "river@yale.edu"
    u.provider = "cas"
    u.uid = "River"
    u.save!
    expect(u.errors).to be_empty
    expect(u.provider).to eq "cas"
    expect(u.uid).to eq "River"
  end

  describe 'deactivate!' do
    it 'deactivates a user' do
      expect(user.deactivated).to eq(false)
      user.deactivate!
      expect(user.deactivated).to eq(true)
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
end
