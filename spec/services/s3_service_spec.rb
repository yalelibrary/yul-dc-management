# frozen_string_literal: true
require "rails_helper"

# Intentionally leaving Webmock allow net connect here for ease of testing against live S3 service.
# When testing a new S3 service, verify that you are running only against test buckets, then
# test new service against live S3 service and get tests passing, then comment out
# the following line and stub connections to S3 for the test, so we can run it in CI.
#
# WebMock.allow_net_connect!

RSpec.describe S3Service, type: :has_vcr do
  before do
    stub_request(:put, "https://yul-test-samples.s3.amazonaws.com/testing_test/test.txt")
      .to_return(status: 200, body: "")
    stub_request(:get, "https://yul-test-samples.s3.amazonaws.com/testing_test/test.txt")
      .to_return(status: 200, body: "these are some test words")
    stub_request(:get, "https://yale-test-image-samples.s3.amazonaws.com/originals/1014543.tif")
      .to_return(status: 200, body: File.open("spec/fixtures/images/access_masters/test_image.tif"))
    stub_request(:put, "https://yale-test-image-samples.s3.amazonaws.com/ptiffs/1014543.tif")
      .with do |request|
        expect(request.headers).to include('X-Amz-Meta-Width' => '100',
                                           'X-Amz-Meta-Height' => '200',
                                           'Content-Type' => 'image/tiff')
      end
      .to_return(status: 200, body: "")
    stub_request(:head, "https://yale-test-image-samples.s3.amazonaws.com/tests/fake_ptiff.tif")
      .to_return(status: 200, headers: { 'X-Amz-Meta-Width' => '100',
                                         'X-Amz-Meta-Height' => '200',
                                         'Content-Type' => 'image/tiff' })
    stub_request(:head, "https://yul-dc-ocr-test.s3.amazonaws.com/fulltext/43/10/14/54/1014543.txt")
      .to_return(status: 200, headers: { 'Content-Type' => 'text/plain' })
    stub_request(:head, "https://yale-test-image-samples.s3.amazonaws.com/originals/1014543.tif")
      .to_return(status: 200, body: "")
    stub_request(:head, "https://yale-test-image-samples.s3.amazonaws.com/originals/fake.tif")
      .to_return(status: 404, body: "")
  end

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

  it "can upload metadata to a given bucket" do
    expect(described_class.upload("testing_test/test.txt", "these are some test words").successful?).to eq true
  end

  it "can download metadata from a given bucket" do
    expect(described_class.download("testing_test/test.txt")).to eq "these are some test words"
  end

  it "can download an image from a given image bucket" do
    child_object_oid = "1014543"
    remote_path = "originals/43/10/14/54/#{child_object_oid}.tif"
    local_path = "spec/fixtures/images/access_masters/#{child_object_oid}.tif"
    VCR.use_cassette("download image 1014543 small") do
      expect(File.exist?(local_path)).to eq false
      described_class.download_image(remote_path, local_path)
      expect(File.exist?(local_path)).to eq true
    end
    File.delete(local_path)
  end

  it "can upload an image to a given image bucket" do
    child_object_oid = "1014543"
    local_path = "spec/fixtures/images/ptiff_images/fake_ptiff.tif"
    remote_path = "ptiffs/#{child_object_oid}.tif"
    expect(File.exist?(local_path)).to eq true
    expect(described_class.upload_image(local_path, remote_path, 'image/tiff', 'width' => '100', 'height' => '200').successful?).to eq true
  end

  it "can tell that an image exists" do
    child_object_oid = "1014543"
    remote_path = "originals/#{child_object_oid}.tif"
    expect(described_class.s3_exists?(remote_path)).to be_truthy
  end

  it "can tell that an image doesn't exist" do
    child_object_oid = "fake"
    remote_path = "originals/#{child_object_oid}.tif"
    expect(described_class.s3_exists?(remote_path)).to eq false
  end

  it "can generate signed URL" do
    child_object_oid = "1014543"
    remote_path = "originals/#{child_object_oid}.tif"
    presigned_url = described_class.presigned_url(remote_path, 600)
    expect(presigned_url).to be_a String
    expect(presigned_url).to start_with "https://#{ENV['S3_SOURCE_BUCKET_NAME']}"
    expect(presigned_url).to include 'X-Amz-Expires=600'
    expect(presigned_url).to include remote_path
  end

  it "can retrieve the metadata from S3" do
    remote_path = "tests/fake_ptiff.tif"
    expect(described_class.remote_metadata(remote_path)).to include(width: "100", height: "200")
  end

  it "can tell if full text exists on an object" do
    child_object_oid = "1014543"
    remote_path = "fulltext/43/10/14/54/#{child_object_oid}.txt"
    expect(described_class.full_text_exists?(remote_path)).to eq(true)
  end
end
