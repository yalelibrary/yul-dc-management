# frozen_string_literal: true
require 'aws-sdk-s3'
require 'rails_helper'

RSpec.describe PyramidalTiffFactory do
  let(:oid) { 1_002_533 }
  let(:ptf) { described_class.new(oid) }
  before do
    stub_request(:get, "https://yale-image-samples.s3.amazonaws.com/originals/1002533.tif")
      .to_return(status: 200, body: File.open('spec/fixtures/images/sample.tiff', 'rb'))
    stub_request(:put, "https://yale-image-samples.s3.amazonaws.com/ptiffs/1002533.tif")
      .to_return(status: 200)
  end

  around do |example|
    original_ptiff_output_directory = ENV["PTIFF_OUTPUT_DIRECTORY"]
    original_access_master_mount = ENV["ACCESS_MASTER_MOUNT"]
    original_temp_image_workspace = ENV['TEMP_IMAGE_WORKSPACE']
    ENV["PTIFF_OUTPUT_DIRECTORY"] = 'spec/fixtures/ptiff_images'
    ENV["ACCESS_MASTER_MOUNT"] = 'spec/fixtures/access_masters'
    ENV['TEMP_IMAGE_WORKSPACE'] = 'spec/fixtures/temp_images'
    example.run
    ENV["PTIFF_OUTPUT_DIRECTORY"] = original_ptiff_output_directory
    ENV["ACCESS_MASTER_MOUNT"] = original_access_master_mount
    ENV['TEMP_IMAGE_WORKSPACE'] = original_temp_image_workspace
  end

  it "can call a wrapper method" do
    expected_file_one = "spec/fixtures/ptiff_images/1002533.tif"
    expect(File.exist?(expected_file_one)).to eq false
    expected_file_two = "spec/fixtures/ptiff_images/1002533.tif"
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
    expect(ptf.access_master_path).to eq "spec/fixtures/access_masters/1002533.tif"
  end

  it "copies the access master to a swing directory" do
    expected_file = "spec/fixtures/temp_images/1002533.tif"
    expect(File.exist?(expected_file)).to eq false
    expect(ptf.copy_access_master_to_working_directory).to eq expected_file
    expect(File.exist?(expected_file)).to eq true
    File.delete(expected_file)
  end

  it "converts the file in the swing directory to a ptiff" do
    expected_file = "spec/fixtures/ptiff_images/1002533.tif"
    expect(File.exist?(expected_file)).to eq false
    ptf.convert_to_ptiff
    expect(File.exist?(expected_file)).to eq true
    File.delete("spec/fixtures/temp_images/1002533.tif")
    File.delete(expected_file)
  end

  it "saves the PTIFF to an S3 bucket" do
    expect(ptf.save_to_s3).to eq "s3://yale-image-samples/ptiffs/1002533.tif"
  end

  xit "bails if the shell script fails" do
    stub_request(:get, "https://yale-image-samples.s3.amazonaws.com/originals/1002533.tif")
      .to_return(status: 200, body: File.open('spec/fixtures/images/sample_cmyk.tiff', 'rb'))
    expect { described_class.convert('c03f65eb5c551594522b4d41843a0b9cf2c40c544c6c06917055241dae37c78e', 'yale-image-samples', 'originals/1002533.tif') }
      .to(raise_error(RuntimeError, /Conversion script exited with error code .*/))
  end

  xit "checks for file checksum and fails if it doesn't match" do
    expect do
      described_class.convert('6', 'yale-image-samples', 'spec/fixtures/images/sample.tiff')
    end.to(
      raise_error(RuntimeError, /\AChecksum failed\. Should be: .*\z/)
    )
  end

  xit "downloads the image from s3 converts the image and uploads the new one to s3" do
    expect(described_class.convert('5ffeed57f61bbc0e58d7d75313b552c2fcaaa6151ef745358e38d3a9212192d2',
                                   'yale-image-samples', 'spec/fixtures/images/sample.tiff')).to eq "s3://yale-image-samples/ptiffs/1002533.tif"
  end
end
