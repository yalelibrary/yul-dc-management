# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "BatchProcesses", type: :request, prep_metadata_sources: true do
  let(:user) { FactoryBot.create(:user) }
  let(:sysadmin_user) { FactoryBot.create(:sysadmin_user, uid: 'johnsmith2530') }
  let(:admin_set) { FactoryBot.create(:admin_set) }
  let(:admin_set_2) { FactoryBot.create(:admin_set, key: 'brbl') }
  let(:parent_object) { FactoryBot.create(:parent_object, oid: "2002826", visibility: "Public", admin_set_id: admin_set_2.id) }
  let(:parent_object_2) { FactoryBot.create(:parent_object, oid: "200300", visibility: "Private", admin_set_id: admin_set_2.id) }

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
      admin_set
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
        csv: File.open(fixture_path + '/csv/short_fixture_ids.csv').read,
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
        csv: File.open(fixture_path + '/csv/short_fixture_ids.csv').read,
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
      let(:file) { fixture_file_upload('csv/short_fixture_ids.csv', 'text/csv') }
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
    around do |example|
      original_metadata_sample_bucket = ENV['SAMPLE_BUCKET']
      original_image_bucket = ENV["S3_SOURCE_BUCKET_NAME"]
      original_path_ocr = ENV['OCR_DOWNLOAD_BUCKET']
      ENV['SAMPLE_BUCKET'] = "yul-test-samples"
      ENV["S3_SOURCE_BUCKET_NAME"] = "yale-test-image-samples"
      ENV['OCR_DOWNLOAD_BUCKET'] = "yul-dc-ocr-test"
      example.run
      ENV['SAMPLE_BUCKET'] = original_metadata_sample_bucket
      ENV["S3_SOURCE_BUCKET_NAME"] = original_image_bucket
      ENV['OCR_DOWNLOAD_BUCKET'] = original_path_ocr
    end

    context "logged in with edit permission" do
      let(:user) { FactoryBot.create(:user) }
      let(:admin_set) { FactoryBot.create(:admin_set, key: 'brbl', label: 'brbl') }
      let!(:parent_object) { FactoryBot.create(:parent_object, oid: "16854285", admin_set_id: admin_set.id) }
      before do
        login_as user
        user.add_role(:editor, admin_set)
      end

      it "delete the pdf but not delete the ptifs" do
        expect(S3Service).to receive(:delete).with("pdfs/85/16/85/42/85/16854285.pdf").once
        expect(S3Service).not_to receive(:delete).with("originals/89/45/67/89/456789.tif")
        delete parent_object_url(parent_object)
        expect(response).to have_http_status(:redirect)
      end
    end

    context "logged in without edit permission" do
      let(:admin_user) { FactoryBot.create(:sysadmin_user) }
      let(:admin_set) { FactoryBot.create(:admin_set, key: 'brbl', label: 'brbl') }
      let!(:parent_object) { FactoryBot.create(:parent_object, oid: "16854285", admin_set_id: admin_set.id) }
      before do
        login_as admin_user
        admin_user.remove_role(:editor)
      end

      it "returns http unauthorized" do
        delete parent_object_url(parent_object)
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /download_template" do
    let(:user) { FactoryBot.create(:user) }
    before do
      login_as user
    end

    it "downloads template for parent objects" do
      get download_template_batch_processes_url(batch_action: "create parent objects")
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq("text/csv; charset=utf-8")
      expect(response.body.to_s).to eq("\xEF\xBB\xBFoid,admin_set,source,aspace_uri,bib,holding,item,barcode,visibility,digital_object_source,preservica_uri,preservica_representation_type")
    end

    it "downloads template for delete child objects" do
      get download_template_batch_processes_url(batch_action: "delete child objects")
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq("text/csv; charset=utf-8")
      expect(response.body.to_s).to eq("\xEF\xBB\xBFoid,admin_set,action")
    end

    it "downloads templates for reassociate" do
      get download_template_batch_processes_url(batch_action: "reassociate child oids")
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq("text/csv; charset=utf-8")
      expect(response.body).to match("\xEF\xBB\xBFchild_oid,parent_oid,order,parent_title,call_number,label,caption,viewing_hint")
    end
  end
end
