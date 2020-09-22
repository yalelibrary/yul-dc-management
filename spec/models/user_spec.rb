# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
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

  context "new user created from CAS" do
    let(:cas_auth_hash) do
      OmniAuth::AuthHash.new(
        provider: 'cas',
        uid: "handsome_dan"
      )
    end
    context "when the user doesn't exist yet" do
      let(:cas_user) { described_class.from_cas(cas_auth_hash) }
      it "makes a new user with CAS data" do
        expect(User.count).to eq 0
        expect(cas_user.uid).to eq "handsome_dan"
        expect(User.count).to eq 1
      end
    end
    context "when the already exists" do
      let(:cas_user) { described_class.from_cas(cas_auth_hash) }
      it "finds the existing user" do
        User.create(provider: "cas", uid: "handsome_dan")
        expect(User.count).to eq 1
        expect(cas_user.uid).to eq "handsome_dan"
        expect(User.count).to eq 1
      end
    end
  end
end
