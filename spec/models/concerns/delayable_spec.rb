# frozen_string_literal: true
require "rails_helper"

RSpec.describe Delayable, prep_metadata_sources: true, prep_admin_sets: true do
  let(:user) { FactoryBot.create(:user) }
  let(:batch_process) { BatchProcess.create(user_id: user.id) }
  let(:parent_object) { FactoryBot.create(:parent_object) }
  let(:csv_upload) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "short_fixture_ids.csv")) }

  # around do |example|
  #   original_image_bucket = ENV["S3_SOURCE_BUCKET_NAME"]
  #   original_access_master_mount = ENV["ACCESS_MASTER_MOUNT"]
  #   ENV["S3_SOURCE_BUCKET_NAME"] = "yale-test-image-samples"
  #   ENV["ACCESS_MASTER_MOUNT"] = File.join("spec", "fixtures", "images", "access_masters")
  #   example.run
  #   ENV["S3_SOURCE_BUCKET_NAME"] = original_image_bucket
  #   ENV["ACCESS_MASTER_MOUNT"] = original_access_master_mount
  # end

  describe "delayed_jobs" do
    # around do |example|
    #   perform_enqueued_jobs do
    #     example.run
    #   end
    # end

    before do
      # login_as(:user)
      # stub_ptiffs_and_manifests
      Delayed::Worker.delay_jobs = false
    end

    it "returns delayed jobs associated with the parent object" do
      batch_connection = batch_process.batch_connections.build(connectable: parent_object)
      batch_connection.save
      parent_object.current_batch_process = batch_process

      SetupMetadataJob.perform_later(parent_object, batch_process, batch_connection)
      expect(Delayed::Worker.new.work_off).to eq [1, 0]

      # assert_enqueued_jobs 1
      # expect do
      #   SetupMetadataJob.perform_later(parent_object, batch_process, batch_connection)
      # end.to change { parent_object.delayed_jobs.count }.by 1
      # expect(parent_object.delayed_jobs).to eq 1

      # batch_process.file = csv_upload
      # batch_process.save!
      # byebug
      # po = ParentObject.find(2034600)
      # byebug

      # end.to change { ParentObject.first.delayed_jobs.count }.by 4
      #   puts "DelayedJobs >>> #{Delayed::Job.count}"
      #   puts "DelayedJobs >>> #{Delayed::Job.count}"
      #   byebug
      #   expect(po.delayed_jobs.count).to eq(4)
      #   expect(ParentObject.count).to eq(5)
    end
  end
end
