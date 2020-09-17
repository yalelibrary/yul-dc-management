# frozen_string_literal: true
require 'aws-sdk-s3'
require 'rails_helper'

RSpec.describe PyramidalTiff, prep_metadata_sources: true, type: :has_vcr do
  let(:oid) { 1_002_533 }
  let(:child_object) { FactoryBot.build_stubbed(:child_object, oid: oid) }
  let(:ptf) { described_class.new(child_object) }

  before do
    stub_request(:get, "https://yale-test-image-samples.s3.amazonaws.com/originals/1002533.tif")
      .to_return(status: 200, body: File.open('spec/fixtures/images/sample.tiff', 'rb'))
    stub_request(:head, "https://yale-test-image-samples.s3.amazonaws.com/originals/1002533.tif")
      .to_return(status: 200)
    stub_request(:put, "https://yale-test-image-samples.s3.amazonaws.com/ptiffs/33/10/02/53/1002533.tif")
      .to_return(status: 200)
    stub_request(:head, "https://yale-test-image-samples.s3.amazonaws.com/ptiffs/33/10/02/53/1002533.tif")
      .to_return(status: 404)
  end

  around do |example|
    original_access_master_mount = ENV["ACCESS_MASTER_MOUNT"]
    ENV["ACCESS_MASTER_MOUNT"] = 'spec/fixtures/images/access_masters'
    original_image_bucket = ENV["S3_SOURCE_BUCKET_NAME"]
    ENV["S3_SOURCE_BUCKET_NAME"] = "yale-test-image-samples"
    example.run
    ENV["ACCESS_MASTER_MOUNT"] = original_access_master_mount
    ENV["S3_SOURCE_BUCKET_NAME"] = original_image_bucket
  end

  describe "validating ptiff generation" do
    let(:has_ptiff_oid) { 1001 }
    let(:child_object_has_ptiff) { FactoryBot.build_stubbed(:child_object, oid: has_ptiff_oid) }
    let(:invalid_ptf) { described_class.new(child_object_has_ptiff) }

    it "logs errors if the job is not valid" do
      expect(ptf).to receive(:generate_ptiff).and_return(height: 100, width: 100)
      expected_file_one = "spec/fixtures/images/temp_images/1001.tif"
      expect(File.exist?(expected_file_one)).to eq false
      expect(ptf.valid?).to eq true
      expect(invalid_ptf.valid?).to eq false
    end
  end

  it "can call a wrapper method" do
    allow(described_class).to receive(:new).and_return(ptf)
    expect(ptf).to receive(:save_to_s3)
    expect(described_class.new(child_object).generate_ptiff)
  end

  it "can be instantiated" do
    expect(ptf).to be_instance_of described_class
    expect(ptf.oid).to eq oid
  end

  it "can find the access master, given an oid" do
    expect(ptf.access_master_path).to eq "spec/fixtures/images/access_masters/33/10/02/53/1002533.tif"
  end

  it "converts the file in the swing directory to a ptiff" do
    swing_temp_dir = "spec/fixtures/images/temp_images/"
    ptiff_tmpdir = "spec/fixtures/images/ptiff_images/"
    expected_file = "#{ptiff_tmpdir}1002533.tif"
    expect(File.exist?(expected_file)).to eq false
    tiff_input_path = ptf.copy_access_master_to_working_directory(swing_temp_dir)
    ptf.convert_to_ptiff(tiff_input_path, ptiff_tmpdir)
    expect(File.exist?(expected_file)).to eq true
    File.delete(tiff_input_path)
    File.delete(expected_file)
  end

  it "saves the PTIFF to an S3 bucket" do
    ptiff_output_path = "spec/fixtures/images/ptiff_images/fake_ptiff.tif"
    expect(ptf.save_to_s3(ptiff_output_path).successful?).to eq true
  end

  it "bails if the shell script fails" do
    stub_request(:get, "https://yale-image-samples.s3.amazonaws.com/originals/1002533.tif")
      .to_return(status: 200, body: File.open('spec/fixtures/images/sample_cmyk.tiff', 'rb'))
    ptiff_tmpdir = "spec/fixtures/images/ptiff_images/"
    ptf.convert_to_ptiff("spec/fixtures/images/sample_cmyk.tiff", ptiff_tmpdir)
    expect(ptf.errors.full_messages.first).to match(/Conversion script exited with error code .*/)
  end

  it "checks for file checksum and fails if it doesn't match" do
    ptf.checksums_match?("spec/fixtures/images/access_masters/test_image.tif", "spec/fixtures/images/temp_images/autumn_test.tif")
    expect(ptf.errors.full_messages.first).to eq("File copy unsuccessful, checksums do not match: {\"oid\":\"1002533\",\"access_master_path\":" \
                  "\"spec/fixtures/images/access_masters/test_image.tif\",\"temp_file_path\":\"spec/fixtures/images/temp_images/autumn_test.tif\"}")
  end

  it "copies the local access master to a swing directory" do
    tmpdir = "spec/fixtures/images/temp_images/"
    expected_file = "#{tmpdir}1002533.tif"
    expect(File.exist?(expected_file)).to eq false
    expect(ptf.copy_access_master_to_working_directory(tmpdir)).to eq expected_file
    expect(File.exist?(expected_file)).to eq true
    File.delete(expected_file)
  end

  context "when pulling access masters from S3" do
    let(:oid) { 1_014_543 }
    let(:oid_with_remote_ptiff) { 111_111 }
    let(:child_with_remote_ptiff) { FactoryBot.build_stubbed(:child_object, oid: oid_with_remote_ptiff) }
    let(:child_object) { FactoryBot.build_stubbed(:child_object, oid: oid) }
    let(:ptf) { described_class.new(child_object) }
    let(:logger_mock) { instance_double("Rails.logger").as_null_object }

    around do |example|
      original_access_master_mount = ENV["ACCESS_MASTER_MOUNT"]
      ENV["ACCESS_MASTER_MOUNT"] = "s3"
      example.run
      ENV["ACCESS_MASTER_MOUNT"] = original_access_master_mount
    end

    before do
      stub_request(:head, "https://yale-test-image-samples.s3.amazonaws.com/originals/43/10/14/54/1014543.tif")
        .to_return(status: 200, body: "", headers: {})
      stub_request(:get, "https://yale-test-image-samples.s3.amazonaws.com/originals/43/10/14/54/1014543.tif")
        .to_return(status: 200, body: File.open('spec/fixtures/images/access_masters/1002533.tif', 'rb'))
      stub_request(:put, "https://yale-test-image-samples.s3.amazonaws.com/ptiffs/43/10/14/54/1014543.tif")
        .to_return(status: 200, body: "", headers: {})
      stub_request(:head, "https://yale-test-image-samples.s3.amazonaws.com/ptiffs/43/10/14/54/1014543.tif")
        .to_return(status: 404, body: "")
      stub_request(:head, "https://yale-test-image-samples.s3.amazonaws.com/originals/11/11/11/11/111111.tif")
        .to_return(status: 200, body: "")
      stub_request(:head, "https://yale-test-image-samples.s3.amazonaws.com/ptiffs/11/11/11/11/111111.tif")
        .to_return(status: 200, body: "")
    end

    it "uses the Yale pairtree algorithm to generate the path to save the ptiff" do
      expect(ptf.remote_ptiff_path).to eq "ptiffs/43/10/14/54/1014543.tif"
    end

    it "uses the Yale pairtree algorithm to fetch access masters from S3" do
      expect(ptf.remote_access_master_path).to eq "originals/43/10/14/54/1014543.tif"
    end

    it "does not perform conversion if remote PTIFF exists" do
      ptiff = described_class.new(child_with_remote_ptiff)
      expect(ptiff.valid?).to be(false)
      expect(ptiff.errors.full_messages.first).to eq("PTIFF exists on S3, not converting: {\"oid\":\"111111\"}")
    end

    it "copies the remote access master to a swing directory" do
      tmpdir = "spec/fixtures/images/temp_images/"
      expected_path = "#{tmpdir}1014543.tif"
      expect(File.exist?(expected_path)).to eq false
      VCR.use_cassette("download image 1014543") do
        expect(ptf.copy_access_master_to_working_directory(tmpdir)).to eq expected_path
      end
      expect(File.exist?(expected_path)).to eq true
      File.delete(expected_path)
    end

    it "can call a wrapper method" do
      allow(described_class).to receive(:new).and_return(ptf)
      expect(ptf).to receive(:save_to_s3)
      VCR.use_cassette("download image 1014543") do
        expect(described_class.new(child_object).generate_ptiff)
      end
    end
  end
end
