# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Reoccurring Jobs", type: :request do
  let(:user) { FactoryBot.create(:user) }

  around do |example|
    original_vpn = ENV['VPN']
    original_metadata_cloud_host = ENV['METADATA_CLOUD_HOST']
    ENV['METADATA_CLOUD_HOST'] = "metadata-api.library.yale.edu"
    ENV['VPN'] = 'true'
    example.run
    ENV['VPN'] = original_vpn
    ENV['METADATA_CLOUD_HOST'] = original_metadata_cloud_host
  end

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
