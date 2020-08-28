# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "Creation of PTIFFs for all ChildObjects", type: :system, prep_metadata_sources: true do
  around do |example|
    original_image_bucket = ENV["S3_SOURCE_BUCKET_NAME"]
    ENV["S3_SOURCE_BUCKET_NAME"] = "yale-test-image-samples"
    perform_enqueued_jobs do
      example.run
    end
    ENV["S3_SOURCE_BUCKET_NAME"] = original_image_bucket
  end

  context "Child of a legacy ParentObject" do
    let(:parent_object_oid) { 2_012_036 }
    let(:child_object_oid) { 1_052_760 }
    before do
      stub_metadata_cloud("2012036")
      stub_request(:head, "https://yale-test-image-samples.s3.amazonaws.com/ptiffs/1052760.tif")
        .to_return(status: 200)
    end

    xit "make all the child_objects and all their ptiffs" do
      parent_object = ParentObject.create(oid: parent_object_oid)
      expect(parent_object.child_objects.count).to eq 5
      expect(parent_object.child_objects.first.remote_ptiff_exists?).to be true
    end
  end
end
