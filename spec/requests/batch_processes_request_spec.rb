# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "BatchProcesses", type: :request, prep_metadata_sources: true do
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

  describe "GET /download with XML" do
    let(:batch_process_xml) do
      FactoryBot.create(
        :batch_process,
        user: user,
        mets_xml: File.open(fixture_path + '/goobi/metadata/16172421/meta.xml').read,
        file_name: "meta.xml"
      )
    end
    it "returns http success" do
      get "/batch_processes/#{batch_process_xml.id}/download"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq("application/xml")
    end
  end

  describe "GET /download with CSV" do
    let(:batch_process_csv) do
      FactoryBot.create(
        :batch_process,
        user: user,
        csv: File.open(fixture_path + '/short_fixture_ids.csv').read,
        file_name: "short_fixture_ids.csv"
      )
    end
    it "returns http success" do
      get "/batch_processes/#{batch_process_csv.id}/download"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq("text/csv; charset=utf-8")
    end
  end

  describe "GET /parent_object/[oid]" do
    let(:batch_process_csv) do
      FactoryBot.create(
        :batch_process,
        user: user,
        csv: File.open(fixture_path + '/short_fixture_ids.csv').read,
        file_name: "short_fixture_ids.csv"
      )
    end

    it "returns http success" do
      get "/batch_processes/#{batch_process_csv.id}/parent_objects/2034600"
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /create" do
    context "with invalid parameters" do
      let(:file) { fixture_file_upload('short_fixture_ids.csv', 'text/csv') }
      # This was previously stubbed in such a way that it would pass no matter what, which is not a
      # meaningful test. Marking pending until we can create a meaningful test
      xit "does not create a new BatchProcess" do
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

  describe "POST /trigger_mets_scan" do
    context "logged in with sysadmin" do
      let(:user) { FactoryBot.create(:sysadmin_user) }
      before do
        login_as user
      end

      it "returns http success" do
        post trigger_mets_scan_batch_processes_url
        expect(response).to redirect_to(batch_processes_path)
      end
    end
    context "logged in without sysadmin" do
      let(:user) { FactoryBot.create(:user) }
      before do
        login_as user
      end
      it "returns http unauthorized" do
        post trigger_mets_scan_batch_processes_url
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
  
  describe "DELETE /delete_parent_object" do
    context "logged in with edit permission" do
      let(:user) { FactoryBot.create(:user) }
      # let!(:batch_process_csv) do
      #   FactoryBot.create(
      #     :batch_process,
      #     user: user,
      #     csv: File.open(fixture_path + '/short_fixture_ids.csv').read,
      #     file_name: "short_fixture_ids.csv"
      #   )
      # end
      let(:parent_object) { FactoryBot.create(:parent_object) }
      before do
        parent_object
        login_as user
      end
      # before do
      #   stub_metadata_cloud("16371253")
      #   stub_full_text('1032318')
      # end
      
      it "returns not found for deleted artifacts" do
        # expect do
        #   batch_process.save
        #   batch_process.create_parent_objects_from_oids(["16371253"], ["ladybird"], ["brbl"])
        # end.to change { ParentObject.count }.from(0).to(1)

        # delete_batch_process = described_class.new(batch_action: "delete parent objects", user_id: user.id)
        # expect do
        #   delete_batch_process.save
        #   delete_batch_process.delete_parent_object(["16371253"], ["ladybird"], ["brbl"])
        # end.to change { ParentObject.count }.from(1).to(0)

        # po = ParentObject.find(ParentObject.first.oid)
        # co = ChildObject.find(po.child_oids)

        delete parent_object_url("#{parent_object.oid}")
        # pdf is deleted
        get "/pdfs/#{parent_object.oid}.pdf"
        # expect(response).to eq have_http_status(:redirect)
        
        
        # manifest is deleted
        get "/manifests/#{parent_object.oid}"
        expect(response).to have_http_status(:not_found)
        
        # solr document is deleted
        get "/parent_objects/#{parent_object.oid}/solr_document"
        expect(response).to have_http_status(:not_found)
        
        # solr document is deleted
        get "/child_objects/#{co.oid}/solr_document"
        expect(response).to have_http_status(:not_found)
      end
    end
    context "logged in without edit permission" do
      let(:admin_user) { FactoryBot.create(:sysadmin_user) }
    end
  end
end
