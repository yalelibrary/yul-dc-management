# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PermissionRequestUser, type: :model, prep_metadata_sources: true, prep_admin_sets: true do
  describe 'with valid attributes' do
    it 'is valid' do
      expect(PermissionRequestUser.new(sub: 'subject', name: 'user name', email: 'email@example.com', email_verified: true, oidc_updated_at: Time.zone.now)).to be_valid
    end

    it 'has the expected fields' do
      u = described_class.new
      time = Time.zone.now
      u.email = 'email@example.com'
      u.sub = 'subject'
      u.name = 'user name'
      u.oidc_updated_at = time
      u.email_verified = true
      u.save!

      expect(u.errors).to be_empty
      expect(u.email).to eq 'email@example.com'
      expect(u.name).to eq 'user name'
      expect(u.email_verified).to eq true
      expect(u.oidc_updated_at).to eq time
    end
  end

  describe 'with validations' do
    it 'verifies that a new request has a subject' do
      permission_request = described_class.new
      expect(permission_request).not_to be_valid
      expect(permission_request.errors.messages[:sub]).to eq ["can't be blank"]
      expect(permission_request.errors.messages[:name]).to eq ["can't be blank"]
      expect(permission_request.errors.messages[:email]).to eq ["can't be blank"]
      expect(permission_request.errors.messages[:email_verified]).to eq ["is not included in the list"]
      expect(permission_request.errors.messages[:oidc_updated_at]).to eq ["can't be blank"]
    end
  end
end
