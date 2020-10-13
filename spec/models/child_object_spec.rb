# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChildObject, type: :model, prep_metadata_sources: true do
  let(:parent_object) { FactoryBot.create(:parent_object, oid: 2_004_628) }
  let(:child_object) { described_class.create(oid: "456789", parent_object: parent_object) }

  around do |example|
    access_master_mount = ENV["ACCESS_MASTER_MOUNT"]
    original_image_bucket = ENV["S3_SOURCE_BUCKET_NAME"]
    ENV["ACCESS_MASTER_MOUNT"] = "s3"
    ENV["S3_SOURCE_BUCKET_NAME"] = "yale-test-image-samples"
    example.run
    ENV["S3_SOURCE_BUCKET_NAME"] = original_image_bucket
    ENV["ACCESS_MASTER_MOUNT"] = access_master_mount
  end

  describe "with a mounted directory for access masters" do
    around do |example|
      access_master_mount = ENV["ACCESS_MASTER_MOUNT"]
      ENV["ACCESS_MASTER_MOUNT"] = "/data"
      example.run
      ENV["ACCESS_MASTER_MOUNT"] = access_master_mount
    end
    it "can return the access_master_path" do
      co_two = described_class.create(oid: "1080001", parent_object: parent_object)
      co_three = described_class.create(oid: "15239530", parent_object: parent_object)
      co_four = described_class.create(oid: "15239590", parent_object: parent_object)
      expect(child_object.access_master_path).to eq "/data/08/89/45/67/89/456789.tif"
      expect(co_two.access_master_path).to eq "/data/00/01/10/80/00/1080001.tif"
      expect(co_three.access_master_path).to eq "/data/03/30/15/23/95/30/15239530.tif"
      expect(co_four.access_master_path).to eq "/data/09/90/15/23/95/90/15239590.tif"
    end
  end

  describe "a child object that already has a remote ptiff" do
    let(:child_object) { described_class.create(oid: "456789", parent_object: parent_object, width: 200, height: 200) }
    before do
      stub_metadata_cloud("2004628")
      stub_request(:head, "https://yale-test-image-samples.s3.amazonaws.com/ptiffs/89/45/67/89/456789.tif")
        .to_return(status: 200)
      stub_request(:head, "https://yale-test-image-samples.s3.amazonaws.com/originals/89/45/67/89/456789.tif")
        .to_return(status: 200)
      parent_object
    end
    it "does not try to generate the ptiff if it already has height & width and remote ptiff already exists" do
      expect(child_object.pyramidal_tiff.valid?).to eq false
      expect(child_object.pyramidal_tiff).not_to receive(:convert_to_ptiff)
      expect(child_object.parent_object.ready_for_manifest?).to be true
    end
  end

  describe "a child object that has successfully generated a ptiff" do
    before do
      stub_metadata_cloud("2004628")
      stub_request(:head, "https://yale-test-image-samples.s3.amazonaws.com/ptiffs/89/45/67/89/456789.tif")
        .to_return(status: 200)
      allow(child_object.pyramidal_tiff).to receive(:valid?).and_return(true)
      allow(child_object.pyramidal_tiff).to receive(:conversion_information).and_return(width: 2591, height: 4056)
      parent_object
    end

    it "does not have a height and width before conversion" do
      expect(child_object.height).to be_nil
      expect(child_object.width).to be_nil
    end

    it "has a valid thumbnail url" do
      first_child_object = parent_object.child_objects.first
      expect(first_child_object.thumbnail_url).to eq "#{(ENV['IIIF_IMAGE_BASE_URL'])}/2/456789/full/200,/0/default.jpg"
    end

    it "has a valid height and width after conversion" do
      expect(child_object.height).to be_nil
      expect(child_object.width).to be_nil
      child_object.convert_to_ptiff
      expect(child_object.height).to be 4056
      expect(child_object.width).to be 2591
    end

    it "can access the parent object" do
      expect(child_object.parent_object).to be_instance_of ParentObject
    end

    it "can return a the remote access master path" do
      expect(child_object.remote_access_master_path).to eq "originals/89/45/67/89/456789.tif"
    end

    it "can return a the remote ptiff path" do
      expect(child_object.remote_ptiff_path).to eq "ptiffs/89/45/67/89/456789.tif"
    end

    it "can receive width and height if they are cached" do
      expect(StaticChildInfo).to receive(:size_for).and_return(width: 50, height: 60)
      expect(child_object).to receive(:remote_ptiff_exists?).and_return true
      expect(child_object.check_for_size_and_file).to be_a(Time)
      expect(child_object.width).to eq(50)
      expect(child_object.height).to eq(60)
    end
  end
end
