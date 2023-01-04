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

    describe 'create' do
      it 'redirects to index with recurring notice' do
        post reoccurring_jobs_path(queue_recurring: 'true')
        expect(response).to have_http_status(302)
      end

      it 'redirects to index with manual notice' do
        post reoccurring_jobs_path(queue_recurring: 'false')
        expect(response).to have_http_status(302)
      end

      it 'redirects to index with in progress notice' do
        ActivityStreamLog.new(status: "Running")
        post reoccurring_jobs_path
        expect(response).to have_http_status(302)
      end
    end
  end
end
