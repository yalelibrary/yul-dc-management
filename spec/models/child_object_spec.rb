# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChildObject, type: :model, prep_metadata_sources: true do
  let(:parent_object) { FactoryBot.create(:parent_object, oid: 2_004_628) }
  let(:child_object) { described_class.create(oid: "456789", parent_object: parent_object) }

  around do |example|
    original_image_bucket = ENV["S3_SOURCE_BUCKET_NAME"]
    ENV["S3_SOURCE_BUCKET_NAME"] = "yale-test-image-samples"
    example.run
    ENV["S3_SOURCE_BUCKET_NAME"] = original_image_bucket
  end

  before do
    stub_metadata_cloud("2004628")
    stub_request(:head, "https://yale-test-image-samples.s3.amazonaws.com/ptiffs/456789.tif")
      .to_return(status: 200)
    parent_object
  end

  it "can access the parent object" do
    expect(child_object.parent_object).to be_instance_of ParentObject
  end

  it "can tell whether its remote ptiff exists" do
    expect(child_object.remote_ptiff_exists?).to eq true
  end
end
