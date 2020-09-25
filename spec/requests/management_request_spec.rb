# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Management root path", type: :request do
  let(:user) { FactoryBot.create(:user) }
  describe "GET /" do
    context "as a logged in user" do
      it "returns http success" do
        login_as(user)
        get "/"
        expect(response).to have_http_status(:success)
        expect(response.body).to match(/Management Dashboard/)
      end
    end
    context "as an unauthenticated user" do
      it "returns http redirect" do
        get "/"
        expect(response).to have_http_status(:success)
        expect(response.body).to match(/You must sign in/)
      end
    end
  end
end
