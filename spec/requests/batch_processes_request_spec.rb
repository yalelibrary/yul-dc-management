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
