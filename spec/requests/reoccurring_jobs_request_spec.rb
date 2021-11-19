# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Reoccurring Jobs", type: :request do
  let(:user) { FactoryBot.create(:user) }

  describe 'with logged in user' do
    before do
      login_as user
    end

    describe "GET /index" do
      it "returns http success" do
        get reoccurring_jobs_url
        expect(response).to have_http_status(:success)
      end
    end

    describe "POST /create" do
      it "correctly responds with invalid attributes" do
        post reoccurring_jobs_url
        expect(response).to redirect_to(reoccurring_jobs_url)
      end
    end
  end
end
