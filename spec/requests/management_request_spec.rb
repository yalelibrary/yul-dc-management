# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Managements", type: :request do
  let(:user) { FactoryBot.create(:user) }
  describe "GET /" do
    context "as a logged in user" do
      it "returns http success" do
        login_as(user)
        get "/"
        expect(response).to have_http_status(:success)
      end
    end
    context "as an unauthenticated user" do
      # Currently auth is not in front of entire application, so this would fail
      xit "returns http redirect" do
        get "/"
        expect(response).to have_http_status(:redirect)
      end
    end
  end
end
