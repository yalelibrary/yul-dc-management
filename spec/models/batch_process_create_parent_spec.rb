# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BatchProcess, type: :model, prep_metadata_sources: true, prep_admin_sets: true do
  subject(:batch_process) { described_class.new }
  let(:user) { FactoryBot.create(:user, uid: "mk2525") }
  let(:admin_set_one) { FactoryBot.create(:admin_set, key: 'jss') }
  let(:no_oid_parent) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "parent_no_oid.csv")) }
  let(:no_admin_set) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "parent_no_admin_set.csv")) }
  let(:no_source) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "parent_no_source.csv")) }

  around do |example|
    original_image_bucket = ENV["S3_SOURCE_BUCKET_NAME"]
    original_access_master_mount = ENV["ACCESS_MASTER_MOUNT"]
    ENV["S3_SOURCE_BUCKET_NAME"] = "yale-test-image-samples"
    ENV['ACCESS_MASTER_MOUNT'] = File.join("spec", "fixtures", "images", "access_masters")
    perform_enqueued_jobs do
      example.run
    end
    ENV["S3_SOURCE_BUCKET_NAME"] = original_image_bucket
    ENV["ACCESS_MASTER_MOUNT"] = original_access_master_mount
  end

  before do
    user.add_role(:editor, admin_set_one)
    login_as(:user)
    batch_process.user_id = user.id
  end

  describe "with the metadata cloud mocked" do
    before do
      stub_metadata_cloud("AS-781086", "aspace")
    end

    context "Create Parent Object batch process with a csv" do
      it "can create a parent_object" do
        expect do
          batch_process.file = no_oid_parent
          batch_process.save
        end.to change { ParentObject.count }.from(0).to(1)
        po = ParentObject.first
        expect(po.oid).not_to be_nil
      end
      it "can fails when csv has no admin set" do
        expect do
          batch_process.file = no_admin_set
          batch_process.save
        end.not_to change { ParentObject.count }
        expect(batch_process.batch_ingest_events[0].reason).to eq("Skipping row [2] with unknown admin set [] for parent: ")
      end
      it "can fails when csv has no source" do
        expect do
          batch_process.file = no_source
          batch_process.save
        end.not_to change { ParentObject.count }
        expect(batch_process.batch_ingest_events[0].reason).to eq("Skipping row [2]. Source cannot be blank.")
      end
    end
  end
end
