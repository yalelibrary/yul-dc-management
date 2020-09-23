# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "OID Imports", type: :request do
  let(:user) { FactoryBot.create(:user) }
  before do
    login_as user
  end
  describe "GET /new" do
    it "renders a successful response" do
      get new_oid_import_url
      expect(response).to be_successful
    end
  end

  describe "POST /create" do
    context "with invalid parameters" do
      let(:file) { fixture_file_upload('short_fixture_ids.csv', 'text/csv') }
      before do
        allow_any_instance_of(OidImport).to receive(:save).and_return(false) # rubocop:disable RSpec/AnyInstance
      end

      it "does not create a new OidImport" do
        expect do
          post oid_imports_url, params: {
            oid_import: {
              csv: file
            }
          }
        end.to change(OidImport, :count).by(0)
        expect(response).to be_successful
        expect(response).not_to redirect_to(oid_imports_path)
      end
    end
  end
end
