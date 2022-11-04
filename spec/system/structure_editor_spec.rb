# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "Structure Editor", type: :system, prep_metadata_sources: true, prep_admin_sets: true, js: true do
  let(:user) { FactoryBot.create(:sysadmin_user) }
  let(:admin_set) { FactoryBot.create(:admin_set, key: 'brbl', label: 'brbl') }
  # parent object has two child objects
  let(:parent_object) { FactoryBot.create(:parent_object, oid: '16172421', admin_set_id: admin_set.id) }
  let(:child_object) { FactoryBot.create(:child_object, oid: '100001', parent_object: parent_object, caption: 'bola') }
  let(:iiif_presentation) { IiifPresentationV3.new(parent_object) }
  
  around do |example|
    original_manifests_base_url = ENV['IIIF_MANIFESTS_BASE_URL']
    original_image_base_url = ENV["IIIF_IMAGE_BASE_URL"]
    original_pdf_url = ENV["PDF_BASE_URL"]
    original_path_ocr = ENV['OCR_DOWNLOAD_BUCKET']
    ENV['IIIF_MANIFESTS_BASE_URL'] = "http://localhost/manifests"
    ENV['IIIF_IMAGE_BASE_URL'] = "http://localhost:8182/iiif"
    ENV["PDF_BASE_URL"] = "http://localhost/pdfs"
    ENV['OCR_DOWNLOAD_BUCKET'] = "yul-dc-ocr-test"
    perform_enqueued_jobs do
      example.run
    end
    ENV['IIIF_MANIFESTS_BASE_URL'] = original_manifests_base_url
    ENV['IIIF_IMAGE_BASE_URL'] = original_image_base_url
    ENV["PDF_BASE_URL"] = original_pdf_url
    ENV['OCR_DOWNLOAD_BUCKET'] = original_path_ocr
  end

  before do
    stub_ptiffs
    stub_pdfs
    user.add_role(:editor, admin_set)
    login_as user
    parent_object
    stub_request(:get, "https://#{ENV['SAMPLE_BUCKET']}.s3.amazonaws.com/manifests/21/16/17/24/21/16172421.json")
      .to_return(status: 200, body: File.open(File.join(fixture_path, "manifests", "16172421.json")).read)
    stub_request(:put, "https://#{ENV['SAMPLE_BUCKET']}.s3.amazonaws.com/manifests/21/16/17/24/21/16172421.json")
      .to_return(status: 200)
    stub_metadata_cloud("16172421")
    stub_metadata_cloud("100001")
  end

  # manifest loads in structure editor
  describe 'can access the homepage' do
    it 'can render a manifest' do
      visit "structure-editor/?manifest=#{parent_object_url(parent_object.oid)}/manifest&token=#{user.token}"
      expect(page).to have_content("#{child_object.oid}")
    end
  end

end




# can add range

# can add canvas

# can delete range

# can delete canvas

# can drag canvas

# can submit structure back to management