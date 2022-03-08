# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Preservica API Requests", type: :request do
  let(:user) { FactoryBot.create(:user) }
  # set up preservica credentials
  around do |example|
    preservica_host = ENV['PRESERVICA_HOST']
    preservica_creds = ENV['PRESERVICA_CREDENTIALS']
    ENV['PRESERVICA_HOST'] = "preservica-dev-v6.library.yale.edu"
    ENV['PRESERVICA_CREDENTIALS'] = '{"brbl": {"username":"kaits", "password":"ellait"}}'
    perform_enqueued_jobs do
      example.run
    end
    ENV['PRESERVICA_HOST'] = preservica_host
    ENV['PRESERVICA_CREDENTIALS'] = preservica_creds
  end

  # log in the user
  # try to create parent object
  # try to create children objects

  describe "GET /" do
    context "as a logged in user" do
      before do
        login_as(user)
      end

      it "returns http success for structural objects" do
        get "https://preservica-dev-v6.library.yale.edu/api/entity/structural-objects/b4dbf905-0cff-45f1-90e2-a62b609d6a28"
        expect(response).to have_http_status(:success)
      end
      it "returns http success for information objects" do
        get "https://preservica-dev-v6.library.yale.edu/api/entity/information-objects/3e6d2e19-79d2-4759-a9a9-f0c08ecea5b5"
        expect(response).to have_http_status(:success)
      end
      # it "returns http success for representations" do
      #   get "https://preservica-dev-v6.library.yale.edu/api/entity/structural-objects/b4dbf905-0cff-45f1-90e2-a62b609d6a28"
      #   expect(response).to have_http_status(:success)
      # end
      # it "returns http success for generations" do
      #   get "https://preservica-dev-v6.library.yale.edu/api/entity/structural-objects/b4dbf905-0cff-45f1-90e2-a62b609d6a28"
      #   expect(response).to have_http_status(:success)
      # end
      it "returns http success for content objects" do
        get "https://preservica-dev-v6.library.yale.edu/api/entity/content-objects/f29ab105-3559-493d-905f-832aa27d96bd"
        expect(response).to have_http_status(:success)
      end
      # it "returns http success for bitstreams" do
      #   get "https://preservica-dev-v6.library.yale.edu/api/entity/structural-objects/b4dbf905-0cff-45f1-90e2-a62b609d6a28"
      #   expect(response).to have_http_status(:success)
      # end
    end

    context "as an unauthenticated user" do
      xit "returns http redirect" do
        get "/"
        expect(response).to have_http_status(:success)
        expect(response.body).to match(/You must sign in/)
      end
    end
  end
end
