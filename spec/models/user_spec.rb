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
end
