# frozen_string_literal: true
require 'aws-sdk-s3'
require 'rails_helper'

RSpec.describe PyramidalTiff, prep_metadata_sources: true, type: :has_vcr do
  let(:oid) { 1_002_532 }
  let(:parent_object) { FactoryBot.build_stubbed(:parent_object) }
  let(:child_object) { FactoryBot.build_stubbed(:child_object, oid: oid) }
  let(:ptf) { described_class.new(child_object) }

  before do
    stub_request(:get, "https://yale-test-image-samples.s3.amazonaws.com/originals/1002532.tif")
      .to_return(status: 200, body: File.open('spec/fixtures/images/sample.tiff', 'rb'))
    stub_request(:head, "https://yale-test-image-samples.s3.amazonaws.com/originals/1002532.tif")
      .to_return(status: 200)
    stub_request(:put, "https://yale-test-image-samples.s3.amazonaws.com/ptiffs/32/10/02/53/1002532.tif")
      .to_return(status: 200)
    stub_request(:head, "https://yale-test-image-samples.s3.amazonaws.com/ptiffs/32/10/02/53/1002532.tif")
      .to_return(status: 200)
    stub_request(:get, "https://yale-test-image-samples.s3.amazonaws.com/ptiffs/01/10/01/1001.tif")
      .to_return(status: 200, body: File.open('spec/fixtures/images/access_primaries/03/33/10/02/53/1002533.tif', 'rb'))
  end

  around do |example|
    original_access_primary_mount = ENV["ACCESS_PRIMARY_MOUNT"]
    ENV["ACCESS_PRIMARY_MOUNT"] = 'spec/fixtures/images/access_primaries'
    original_image_bucket = ENV["S3_SOURCE_BUCKET_NAME"]
    ENV["S3_SOURCE_BUCKET_NAME"] = "yale-test-image-samples"
    example.run
    ENV["ACCESS_PRIMARY_MOUNT"] = original_access_primary_mount
    ENV["S3_SOURCE_BUCKET_NAME"] = original_image_bucket
  end

  describe "validating ptiff generation" do
    let(:has_ptiff_oid) { 1001 }
    let(:child_object_has_ptiff) { FactoryBot.build_stubbed(:child_object, oid: has_ptiff_oid) }
    let(:invalid_ptf) { described_class.new(child_object_has_ptiff) }

    it "logs errors if the job is not valid" do
      allow(S3Service).to receive(:s3_exists?).and_return(false)
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

  it "can find the access primary, given an oid" do
    expect(ptf.access_primary_path).to eq "spec/fixtures/images/access_primaries/03/32/10/02/53/1002532.tif"
  end

  it "builds a command with args" do
    expect(ptf.build_command("tempdir", "b", "c")).to match(/tempdir/)
  end

  it "converts the file in the swing directory to a ptiff" do
    swing_temp_dir = "spec/fixtures/images/temp_images/"
    ptiff_tmpdir = "spec/fixtures/images/ptiff_images/"
    expected_file = "#{ptiff_tmpdir}1002532.tif"
    expect(File.exist?(expected_file)).to eq false
    tiff_input_path = ptf.copy_access_primary_to_working_directory(swing_temp_dir)
    conversion_information = ptf.convert_to_ptiff(tiff_input_path, ptiff_tmpdir)
    expect(conversion_information).to eq(height: "434", width: "650")
    expect(File.exist?(expected_file)).to eq true
    File.delete(tiff_input_path)
    File.delete(expected_file)
  end

  it "saves the PTIFF to an S3 bucket" do
    ptiff_output_path = "spec/fixtures/images/ptiff_images/fake_ptiff.tif"
    expect(ptf.save_to_s3(ptiff_output_path, "width" => 500, "height" => 600).successful?).to eq true
  end

  it "bails if the shell script fails" do
    stub_request(:get, "https://yale-image-samples.s3.amazonaws.com/originals/1002532.tif")
      .to_return(status: 200, body: File.open('spec/fixtures/images/sample_cmyk.tiff', 'rb'))
    ptiff_tmpdir = "spec/fixtures/images/ptiff_images/"
    ptf.convert_to_ptiff(__FILE__, ptiff_tmpdir)
    expect(ptf.errors.full_messages.first).to match(/Conversion script exited with error code .*/)
  end

  it "doesn't try to save to S3 if the shell script fails" do
    stub_request(:get, "https://yale-image-samples.s3.amazonaws.com/originals/1002532.tif")
      .to_return(status: 200, body: File.open('spec/fixtures/images/sample_cmyk.tiff', 'rb'))
    ptiff_tmpdir = "spec/fixtures/images/ptiff_images/"
    allow(described_class).to receive(:new).and_return(ptf)
    allow(ptf).to receive(:convert_to_ptiff).and_return(ptf.convert_to_ptiff(__FILE__, ptiff_tmpdir))
    expect(ptf).not_to receive(:save_to_s3)
    expect(described_class.new(child_object).generate_ptiff)
    expect(ptf.errors.full_messages.first).to match(/Conversion script exited with error code .*/)
  end

  it "copies the local access primary to a swing directory" do
    tmpdir = "spec/fixtures/images/temp_images/"
    expected_file = "#{tmpdir}1002532.tif"
    expect(File.exist?(expected_file)).to eq false
    expect(ptf.copy_access_primary_to_working_directory(tmpdir)).to eq expected_file
    expect(File.exist?(expected_file)).to eq true
    File.delete(expected_file)
  end

  it "original_file_exists? responds correctly for mets" do
    child_object.parent_object = parent_object
    expect(parent_object).to receive(:from_mets).and_return(true).once
    expect(File).to receive(:exist?).and_return(true).once
    ptf.original_file_exists?
  end

  context "when using s3 access primary mount" do
    around do |example|
      original_mount = ENV['ACCESS_PRIMARY_MOUNT']
      ENV['ACCESS_PRIMARY_MOUNT'] = 's3'
      example.run
      ENV['ACCESS_PRIMARY_MOUNT'] = original_mount
    end

    it "original_file_exists? responds correctly s3" do
      child_object.parent_object = parent_object
      expect(S3Service).to receive(:s3_exists?).and_return(true).once
      ptf.original_file_exists?
    end
  end

  context "when pulling access primaries from S3" do
    let(:oid) { 1_014_543 }
    let(:oid_with_remote_ptiff) { 111_111 }
    let(:parent_object_with_remote_ptiff) { FactoryBot.create(:parent_object, oid: 111_000) }
    let(:child_with_remote_ptiff) { FactoryBot.create(:child_object, oid: oid_with_remote_ptiff, parent_object_oid: 111_000) }
    let(:child_object) { FactoryBot.build_stubbed(:child_object, oid: oid) }
    let(:ptf) { described_class.new(child_object) }
    let(:logger_mock) { instance_double("Rails.logger").as_null_object }
    let(:user) { FactoryBot.create(:user) }
    let(:batch_process) { FactoryBot.create(:batch_process, user: user) }

    around do |example|
      original_access_primary_mount = ENV["ACCESS_PRIMARY_MOUNT"]
      ENV["ACCESS_PRIMARY_MOUNT"] = "s3"
      example.run
      ENV["ACCESS_PRIMARY_MOUNT"] = original_access_primary_mount
    end

    before do
      stub_request(:head, "https://yale-test-image-samples.s3.amazonaws.com/originals/43/10/14/54/1014543.tif")
        .to_return(status: 200, body: "", headers: {})
      stub_request(:get, "https://yale-test-image-samples.s3.amazonaws.com/originals/43/10/14/54/1014543.tif")
        .to_return(status: 200, body: File.open('spec/fixtures/images/access_primaries/1002533.tif', 'rb'))
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

    it "uses the Yale pairtree algorithm to fetch access primaries from S3" do
      expect(ptf.remote_access_primary_path).to eq "originals/43/10/14/54/1014543.tif"
    end

    it "does not perform conversion if remote PTIFF exists" do
      expect do
        parent_object_with_remote_ptiff.current_batch_process = batch_process
        parent_object_with_remote_ptiff.current_batch_connection = BatchConnection.create!(connectable: parent_object_with_remote_ptiff, batch_process: batch_process)
        parent_object_with_remote_ptiff.save!
        allow(child_with_remote_ptiff).to receive(:parent_object).and_return(parent_object_with_remote_ptiff)
        child_with_remote_ptiff.current_batch_connection = BatchConnection.create!(connectable: child_with_remote_ptiff, batch_process: batch_process)
        ptiff = described_class.new(child_with_remote_ptiff)
        expect(ptiff.valid?).to be(true)
      end.to change { IngestEvent.count }.by(1)
    end

    it "copies the remote access primary to a swing directory" do
      tmpdir = "spec/fixtures/images/temp_images/"
      expected_path = "#{tmpdir}1014543.tif"
      expect(File.exist?(expected_path)).to eq false
      VCR.use_cassette("download image 1014543") do
        expect(ptf.copy_access_primary_to_working_directory(tmpdir)).to eq expected_path
      end
      expect(File.exist?(expected_path)).to eq true
      File.delete(expected_path)
    end

    it "can call a wrapper method" do
      allow(described_class).to receive(:new).and_return(ptf)
      expect(ptf).to receive(:save_to_s3).with(anything, { height: "434", width: "650" })
      VCR.use_cassette("download image 1014543") do
        expect(described_class.new(child_object).generate_ptiff)
      end
    end
  end
end
