# frozen_string_literal: true
require 'rails_helper'

RSpec.describe OmniauthCallbacksController do
  include Devise::Test::ControllerHelpers

  before do
    request.env["devise.mapping"] = Devise.mappings[:user]
    request.env["omniauth.auth"] = OmniAuth.config.mock_auth[:cas]
  end
  OmniAuth.config.mock_auth[:cas] =
    OmniAuth::AuthHash.new(
      provider: 'cas',
      uid: "handsome_dan"
    )

  # If a user logs in and we can tell what page they were on before logging in it will redirect them to the page they were previously on
  context "when origin is present" do
    before do
      User.create(provider: 'cas',
                  uid: 'handsome_dan')
      request.env["omniauth.origin"] = '/yale-only-map-of-china'
    end

    it "redirects to origin" do
      post :cas
      expect(response.redirect_url).to eq 'http://test.host/yale-only-map-of-china'
      expect(flash[:notice]).to eq "Successfully authenticated from CAS account."
    end
  end

  # If a user logs in and we cannot tell what page they were on before logging in it will redirect them to the home page
  context "when origin is missing" do
    before do
      User.create(provider: 'cas',
                  uid: 'handsome_dan')
    end
    it "redirects to dashboard" do
      post :cas
      expect(response.redirect_url).to include "http://test.host/"
      expect(flash[:notice]).to eq "Successfully authenticated from CAS account."
    end
  end

  context "when unexpected cas user tries to login" do
    it "redirect to origin" do
      post :cas
      expect(flash[:notice]).not_to eq "Successfully authenticated from CAS account."
      expect(flash[:alert]).to eq "Could not authenticate you from CAS because \"the user is not in the database\"."
      expect(response.redirect_url).to eq "http://test.host/"
    end
  end

  context "when deactivated user tries to login" do
    before do
      User.create(provider: 'cas',
                  uid: 'handsome_dan',
                  deactivated: true)
    end
    it "redirect to origin" do
      post :cas
      expect(flash[:notice]).not_to eq "Successfully authenticated from CAS account."
      expect(flash[:alert]).to eq "Could not authenticate you from CAS because \"the account has been deactivated\"."
      expect(response.redirect_url).to eq "http://test.host/"
    end
  end
end
