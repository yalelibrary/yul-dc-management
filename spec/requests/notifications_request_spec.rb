# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Notifications", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get '/notifications'
      expect(response).to redirect_to(user_session_path)
    end
  end
end
