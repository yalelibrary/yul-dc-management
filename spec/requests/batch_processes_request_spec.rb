require 'rails_helper'

RSpec.describe "BatchProcesses", type: :request do

  xdescribe "GET /index" do
    it "returns http success" do
      get "/batch_processes/index"
      expect(response).to have_http_status(:success)
    end
  end

  xdescribe "GET /new" do
    it "returns http success" do
      get "/batch_processes/new"
      expect(response).to have_http_status(:success)
    end
  end

  xdescribe "GET /create" do
    it "returns http success" do
      get "/batch_processes/create"
      expect(response).to have_http_status(:success)
    end
  end

end
