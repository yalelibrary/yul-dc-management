# frozen_string_literal: true
require 'aws-sdk-s3'
require 'rails_helper'
require 'yale_convert'

RSpec.describe YaleConvert do
  before do
    stub_request(:get, "https://yale-image-samples.s3.amazonaws.com/originals/1002533.tif")
      .to_return(status: 200, body: File.open('spec/fixtures/images/sample.tiff', 'rb'))
    stub_request(:put, "https://yale-image-samples.s3.amazonaws.com/ptiffs/1002533.tif")
      .to_return(status: 200)
  end

  around do |example|
    original_temp_image_workspace = ENV['TEMP_IMAGE_WORKSPACE']
    ENV['TEMP_IMAGE_WORKSPACE'] = 'spec/fixtures/temp_images'
    example.run
    ENV['TEMP_IMAGE_WORKSPACE'] = original_temp_image_workspace
  end

  it "takes a path to a file and makes a copy of it in TEMP_IMAGE_WORKSPACE" do
    described_class.make_tempfile('spec/fixtures/images/sample.tiff')
    expect(File.exist?("spec/fixtures/temp_images/sample.tiff")).to eq true
  end

  it "checks for file checksum and fails if it doesn't match" do
    expect do
      described_class.convert('6', 'yale-image-samples', 'spec/fixtures/images/sample.tiff')
    end.to(
      raise_error(RuntimeError, /\AChecksum failed\. Should be: .*\z/)
    )
  end

  it "downloads the image from s3 converts the image and uploads the new one to s3" do
    expect(described_class.convert('5ffeed57f61bbc0e58d7d75313b552c2fcaaa6151ef745358e38d3a9212192d2',
                                   'yale-image-samples', 'spec/fixtures/images/sample.tiff')).to eq "s3://yale-image-samples/ptiffs/1002533.tif"
  end

  it "bails if the shell script fails" do
    stub_request(:get, "https://yale-image-samples.s3.amazonaws.com/originals/1002533.tif")
      .to_return(status: 200, body: File.open('spec/fixtures/images/sample_cmyk.tiff', 'rb'))
    expect { described_class.convert('c03f65eb5c551594522b4d41843a0b9cf2c40c544c6c06917055241dae37c78e', 'yale-image-samples', 'originals/1002533.tif') }
      .to(raise_error(RuntimeError, /Conversion script exited with error code .*/))
  end
end
