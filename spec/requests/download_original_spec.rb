# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Download Original API', type: :request, prep_admin_sets: true do
  let(:source) { FactoryBot.create(:metadata_source) }
  let(:user) { FactoryBot.create(:sysadmin_user) }
  let(:admin_set) { AdminSet.first }
  let(:oid) { 2_034_600 }
  let(:oid_2) { 137_105_661 }
  let(:parent) { FactoryBot.create(:parent_object, oid: oid, admin_set: admin_set, visibility: 'Yale Community Only', authoritative_metadata_source_id: source.id) }
  let(:parent_2) { FactoryBot.create(:parent_object, oid: oid_2, admin_set: admin_set, visibility: 'Private', authoritative_metadata_source_id: source.id) }
  let(:child_object) { FactoryBot.create(:child_object, oid: '123456', parent_object: parent) }
  let(:child_object_2) { FactoryBot.create(:child_object, oid: '2345678', parent_object: parent_2) }
  let(:headers) { { 'CONTENT_TYPE' => 'application/json' } }
  let(:logger_mock) { instance_double('Rails.logger').as_null_object }

  around do |example|
    original_image_bucket = ENV['S3_SOURCE_BUCKET_NAME']
    original_download_bucket = ENV['S3_DOWNLOAD_BUCKET_NAME']
    original_access_master_mount = ENV['ACCESS_MASTER_MOUNT']
    ENV['S3_SOURCE_BUCKET_NAME'] = 'not-a-real-bucket'
    ENV['S3_DOWNLOAD_BUCKET_NAME'] = 'fake-download-bucket'
    ENV['ACCESS_MASTER_MOUNT'] = File.join(fixture_path, 'images/ptiff_images')
    perform_enqueued_jobs do
      example.run
    end
    ENV['S3_SOURCE_BUCKET_NAME'] = original_image_bucket
    ENV['S3_DOWNLOAD_BUCKET_NAME'] = original_download_bucket
    ENV['ACCESS_MASTER_MOUNT'] = original_access_master_mount
  end

  before do
    allow(Rails.logger).to receive(:error) { :logger_mock }
    stub_request(:head, 'https://fake-download-bucket.s3.amazonaws.com/download/tiff/56/12/34/56/123456.tif')
        .to_return(status: 200, body: '', headers: {})
    parent
    parent_2
    child_object
    child_object_2
    login_as user
    user.add_role(:editor, admin_set)
  end

  describe 'POST /api/download/stage/child/:oid' do
    it 'creates a new job to copy to s3' do
      expect(SaveOriginalToS3Job).to receive(:perform_later).once
      valid_params = { oid: child_object.oid }
      get "/api/download/stage/child/#{child_object.oid}", params: { download_original: valid_params }, headers: headers
      expect(response.status).to eq(200)
    end

    it 'errors if object is not YCO or Public' do
      expect(SaveOriginalToS3Job).not_to receive(:perform_later)
      private_visibility_params = { oid: child_object_2.oid }
      get "/api/download/stage/child/#{child_object_2.oid}", params: { download_original: private_visibility_params }, headers: headers
      expect(response).to have_http_status(:forbidden) # 403
    end

    it 'errors if child oid is not found' do
      expect(SaveOriginalToS3Job).not_to receive(:perform_later)
      made_up_oid_params = { oid: 4_545_454_545 }
      get '/api/download/stage/child/4545454545', params: { download_original: made_up_oid_params }, headers: headers
      expect(Rails.logger).to have_received(:error)
        .with('Child object with oid: 4545454545 not found.')
      expect(response).to have_http_status(:bad_request) # 400
    end
  end
end
