# frozen_string_literal: true
require 'aws-sdk-s3'
require 'rails_helper'

RSpec.describe PyramidalTiffFactory do
  let(:oid) { "1002533" }
  let(:ptf) { described_class.new(oid) }

  before do
    stub_request(:get, "https://yale-image-samples.s3.amazonaws.com/originals/1002533.tif")
      .to_return(status: 200, body: File.open('spec/fixtures/images/sample.tiff', 'rb'))
    stub_request(:put, "https://yale-test-image-samples.s3.amazonaws.com/ptiffs/1002533.tif")
      .to_return(status: 200)
  end

  around do |example|
    original_image_bucket = ENV["S3_SOURCE_BUCKET_NAME"]
    original_ptiff_output_directory = ENV["PTIFF_OUTPUT_DIRECTORY"]
    original_access_master_mount = ENV["ACCESS_MASTER_MOUNT"]
    original_temp_image_workspace = ENV['TEMP_IMAGE_WORKSPACE']
    ENV["S3_SOURCE_BUCKET_NAME"] = "yale-test-image-samples"
    ENV["PTIFF_OUTPUT_DIRECTORY"] = 'spec/fixtures/images/ptiff_images'
    ENV["ACCESS_MASTER_MOUNT"] = 'spec/fixtures/images/access_masters'
    ENV['TEMP_IMAGE_WORKSPACE'] = 'spec/fixtures/images/temp_images'
    example.run
    ENV["S3_SOURCE_BUCKET_NAME"] = original_image_bucket
    ENV["PTIFF_OUTPUT_DIRECTORY"] = original_ptiff_output_directory
    ENV["ACCESS_MASTER_MOUNT"] = original_access_master_mount
    ENV['TEMP_IMAGE_WORKSPACE'] = original_temp_image_workspace
  end

  it "can call a wrapper method" do
    expected_file_one = "spec/fixtures/images/temp_images/1002533.tif"
    expect(File.exist?(expected_file_one)).to eq false
    expected_file_two = "spec/fixtures/images/ptiff_images/1002533.tif"
    expect(File.exist?(expected_file_two)).to eq false
    expect(described_class.generate_ptiff_from(oid))
    expect(File.exist?(expected_file_one)).to eq true
    File.delete(expected_file_one)
    expect(File.exist?(expected_file_two)).to eq true
    File.delete(expected_file_two)
  end

  it "can be instantiated" do
    expect(ptf).to be_instance_of described_class
    expect(ptf.oid).to eq oid
  end

  it "can find the access master, given an oid" do
    expect(ptf.access_master_path).to eq "spec/fixtures/images/access_masters/1002533.tif"
  end

  it "converts the file in the swing directory to a ptiff" do
    expected_file = "spec/fixtures/images/ptiff_images/1002533.tif"
    expect(File.exist?(expected_file)).to eq false
    tiff_input_path = ptf.copy_local_access_master_to_working_directory
    ptf.convert_to_ptiff(tiff_input_path)
    expect(File.exist?(expected_file)).to eq true
    File.delete("spec/fixtures/images/temp_images/1002533.tif")
    File.delete(expected_file)
  end

  it "saves the PTIFF to an S3 bucket" do
    ptiff_output_path = "spec/fixtures/images/ptiff_images/fake_ptiff.tif"
    expect(ptf.save_to_s3(ptiff_output_path).successful?).to eq true
  end

  it "bails if the shell script fails" do
    stub_request(:get, "https://yale-image-samples.s3.amazonaws.com/originals/1002533.tif")
      .to_return(status: 200, body: File.open('spec/fixtures/images/sample_cmyk.tiff', 'rb'))
    expect { ptf.convert_to_ptiff("spec/fixtures/images/sample_cmyk.tiff") }
      .to(raise_error(RuntimeError, /Conversion script exited with error code .*/))
  end

  it "checks for file checksum and fails if it doesn't match" do
    expect do
      ptf.compare_checksums("spec/fixtures/images/access_masters/test_image.tif", "spec/fixtures/images/temp_images/autumn_test.tif")
    end.to(
      raise_error(RuntimeError, /\AChecksum failed. Should be: .*\z/)
    )
  end

  it "copies the local access master to a swing directory" do
    expected_file = "spec/fixtures/images/temp_images/1002533.tif"
    expect(File.exist?(expected_file)).to eq false
    expect(ptf.copy_local_access_master_to_working_directory).to eq expected_file
    expect(File.exist?(expected_file)).to eq true
    File.delete(expected_file)
  end

  context "when pulling access masters from S3" do
    let(:oid) { "1014543" }
    let(:ptf) { described_class.new(oid) }

    around do |example|
      original_access_master_source = ENV["ACCESS_MASTER_SOURCE"]
      ENV["ACCESS_MASTER_SOURCE"] = "S3"
      example.run
      ENV["ACCESS_MASTER_SOURCE"] = original_access_master_source
    end

    before do
      stub_request(:head, "https://yale-test-image-samples.s3.amazonaws.com/originals/1014543.tif")
        .to_return(status: 200, body: "", headers: {})
      stub_request(:get, "https://yale-test-image-samples.s3.amazonaws.com/originals/1014543.tif")
        .to_return(status: 200, body: File.open('spec/fixtures/images/access_masters/1002533.tif', 'rb'))
      stub_request(:put, "https://yale-test-image-samples.s3.amazonaws.com/ptiffs/1014543.tif")
        .to_return(status: 200, body: "", headers: {})
    end

    it "copies the remote access master to a swing directory" do
      expected_path = "spec/fixtures/images/temp_images/1014543.tif"
      expect(File.exist?(expected_path)).to eq false
      expect(ptf.copy_remote_access_master_to_working_directory).to eq expected_path
      expect(File.exist?(expected_path)).to eq true
      File.delete(expected_path)
    end

    it "can call a wrapper method" do
      expected_file_one = "spec/fixtures/images/temp_images/1014543.tif"
      expect(File.exist?(expected_file_one)).to eq false
      expected_file_two = "spec/fixtures/images/ptiff_images/1014543.tif"
      expect(File.exist?(expected_file_two)).to eq false
      expect(described_class.generate_ptiff_from(oid))
      expect(File.exist?(expected_file_one)).to eq true
      File.delete(expected_file_one)
      expect(File.exist?(expected_file_two)).to eq true
      File.delete(expected_file_two)
    end
  end
end
