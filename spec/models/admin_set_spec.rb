# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdminSet, type: :model do
  let(:admin_set) { FactoryBot.create(:admin_set, key: "key", label: "label", homepage: "http://test.com") }
  it "returns proper values" do
    expect(admin_set.key).to eq "key"
    expect(admin_set.label).to eq "label"
    expect(admin_set.homepage).to eq "http://test.com"
  end
  it "is invalid without all properties set" do
    expect(admin_set.valid?).to be_truthy
    admin_set.key = nil
    expect(admin_set.valid?).to be_falsey
  end
end
