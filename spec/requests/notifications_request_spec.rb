# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Notifications", prep_metadata_sources: true, type: :request do
  before do
    stub_metadata_cloud("2012143", "ladybird")
  end

  let(:user) { FactoryBot.create(:user) }
  let(:ladybird) { 1 }
  let(:parent_object) { FactoryBot.create(:parent_object, oid: '2012143', authoritative_metadata_source_id: ladybird) }
  let(:valid_attributes) do
    {
      recipient_type: "User",
      recipient_id: user.id,
      type: "IngestNotification",
      params: {
        reason: "Test",
        status: "failed",
        parent_object: parent_object
      }
    }
  end

  context "as an unauthenticated user" do
    describe "GET /index" do
      it "returns http redirect" do
        get '/notifications'
        expect(response).to redirect_to(user_cas_omniauth_authorize_path)
      end
    end
  end

  context "as an authenticated user" do
    before do
      sign_in user
    end
    describe "GET /index" do
      it "returns http success" do
        get '/notifications'
        expect(response).to be_successful
      end
    end

    describe "DELETE /destroy" do
      it "destroys the requested notification" do
        notification = Notification.create!(valid_attributes)
        expect do
          delete notification_url(notification)
        end.to change(Notification, :count).by(-1)
      end

      it "redirects to the parent_objects list" do
        notification = Notification.create!(valid_attributes)
        delete notification_url(notification)
        expect(response).to redirect_to(notifications_url)
      end
    end
  end
end
