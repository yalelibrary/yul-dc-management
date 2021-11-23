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
  end
end
