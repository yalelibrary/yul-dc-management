# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdminSet, type: :model do
  let(:admin_set) { FactoryBot.create(:admin_set, key: "brbl", label: "label", homepage: "http://test.com") }
  let(:admin_set_two) { FactoryBot.create(:admin_set, key: "key", label: "label", homepage: "http://test.com") }
  let(:user) { FactoryBot.create(:user) }

  it "returns proper values" do
    expect(admin_set.key).to eq "brbl"
    expect(admin_set.label).to eq "label"
    expect(admin_set.homepage).to eq "http://test.com"
  end

  it "is invalid without all properties set" do
    expect(admin_set.valid?).to be_truthy
    admin_set.key = nil
    expect(admin_set.valid?).to be_falsey
  end

  describe "user roles" do
    it "adds a viewer" do
      expect(user.roles).to be_empty
      admin_set.add_viewer(user)
      expect(user.roles.count).to eq(1)
      expect(user.roles.first.name).to eq("viewer")
    end

    it "removes a viewer" do
      admin_set.add_viewer(user)
      expect(user.roles.count).to eq(1)
      admin_set.remove_viewer(user)
      expect(user.roles.count).to eq(0)
    end

    it "adds an editor" do
      expect(user.roles).to be_empty
      admin_set.add_editor(user)
      expect(user.roles.count).to eq(1)
      expect(user.roles.first.name).to eq("editor")
    end

    it "removes an editor" do
      admin_set.add_editor(user)
      expect(user.roles.count).to eq(1)
      admin_set.remove_editor(user)
      expect(user.roles.count).to eq(0)
    end

    it "removes an editor when a viewer is added" do
      admin_set.add_editor(user)
      expect(user.roles.count).to eq(1)
      admin_set.add_viewer(user)
      expect(user.roles.count).to eq(1)
      expect(user.roles.first.name).to eq("viewer")
    end

    it "removes a viewer when an editor is added" do
      admin_set.add_viewer(user)
      expect(user.roles.count).to eq(1)
      admin_set.add_editor(user)
      expect(user.roles.count).to eq(1)
      expect(user.roles.first.name).to eq("editor")
    end
  end

  describe "preservica credentials" do
    around do |example|
      original_preservica_cred = ENV['PRESERVICA_CREDENTIALS']
      ENV['PRESERVICA_CREDENTIALS'] = '{
        "brbl": {
          "username": "foo",
          "password": "bar"
         },
         "mssa": {
          "username": "baz",
          "password": "boop"
         }
      }'
      example.run
      ENV['PRESERVICA_CREDENTIALS'] = original_preservica_cred
    end

    it "verifies if credentials exist" do
      expect(admin_set.preservica_credentials_verified).to eq true
      expect(admin_set_two.preservica_credentials_verified).to eq false
    end
  end
end
