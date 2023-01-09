# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Download Original API', type: :request, prep_metadata_sources: true, prep_admin_sets: true do
  let(:user) { FactoryBot.create(:sysadmin_user) }
  let(:admin_set) { FactoryBot.create(:admin_set) }
  let(:oid) { 2_034_600 }
  let(:oid_2) { 17_105_661 }
  let(:parent) { FactoryBot.create(:parent_object, oid: oid, admin_set: admin_set, visibility: 'Yale Community Only') }
  let(:parent_2) { FactoryBot.create(:parent_object, oid: oid_2, admin_set: admin_set, visibility: 'Private') }
  let(:child_object) { FactoryBot.create(:child_object, oid: '123456', parent_object: parent) }
  let(:child_object_2) { FactoryBot.create(:child_object, oid: '2345678', parent_object: parent_2) }
  let(:headers) { { 'CONTENT_TYPE' => 'application/json' } }

  around do |example|
    original_image_bucket = ENV['S3_SOURCE_BUCKET_NAME']
    original_download_bucket = ENV['S3_DOWNLOAD_BUCKET_NAME']
    original_access_master_mount = ENV["ACCESS_MASTER_MOUNT"]
    ENV['S3_SOURCE_BUCKET_NAME'] = 'not-a-real-bucket'
    ENV['S3_DOWNLOAD_BUCKET_NAME'] = 'fake-download-bucket'
    ENV["ACCESS_MASTER_MOUNT"] = File.join(fixture_path, "images/ptiff_images")
    example.run
    ENV['S3_SOURCE_BUCKET_NAME'] = original_image_bucket
    ENV['S3_DOWNLOAD_BUCKET_NAME'] = original_download_bucket
    ENV["ACCESS_MASTER_MOUNT"] = original_access_master_mount
  end

  before do
    stub_metadata_cloud(oid)
    stub_metadata_cloud(oid_2)
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
      expect do
        get "/api/download/stage/child/#{child_object.oid}", params: {oid: child_object.oid}, headers: headers
      end.to change {Delayed::Job.count}.by(1)
      # expect(SaveOriginalToS3Job).to receive(:perform_later).once
      # expect(response).to have_http_status(:ok) # 200
    end

    it 'errors if object is not YCO or Public' do
      get "/api/download/stage/child/#{child_object_2.oid}", params: {oid: child_object_2.oid}, headers: headers
      expect(SaveOriginalToS3Job).not_to receive(:perform_later)
      expect(response).to have_http_status(:forbidden) # 403
    end
  end
end
