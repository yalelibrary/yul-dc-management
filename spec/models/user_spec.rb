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
end
