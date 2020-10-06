# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "BatchProcesses", type: :request do
  let(:user) { FactoryBot.create(:user) }
  before do
    login_as user
  end

  describe "GET /new" do
    it "returns http success" do
      get "/batch_processes/new"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /download_xml" do
    let(:batch_process) do
      FactoryBot.create(
        :batch_process,
        user: user,
        mets_xml: File.open(fixture_path + '/goobi/min_valid_xml.xml').read,
        file_name: "min_valid_xml.xml"
      )
    end
    it "returns http success" do
      get "/batch_processes/#{batch_process.id}/download_xml"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq("application/xml")
    end
  end

  describe "GET /download_csv" do
    let(:batch_process) do
      FactoryBot.create(
        :batch_process,
        user: user,
        csv: File.open(fixture_path + '/short_fixture_ids.csv').read,
        file_name: "short_fixture_ids.csv"
      )
    end
    it "returns http success" do
      get "/batch_processes/#{batch_process.id}/download_csv"
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /create" do
    context "with invalid parameters" do
      let(:file) { fixture_file_upload('short_fixture_ids.csv', 'text/csv') }
      before do
        allow_any_instance_of(BatchProcess).to receive(:save).and_return(false) # rubocop:disable RSpec/AnyInstance
      end

      it "does not create a new BatchProcess" do
        expect do
          post batch_processes_url, params: {
            batch_process: {
              csv: file
            }
          }
        end.to change(BatchProcess, :count).by(0)
        expect(response).to be_successful
        expect(response).not_to redirect_to(batch_processes_path)
      end
    end
  end
end
