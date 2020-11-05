# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ParentObject, type: :model, prep_metadata_sources: true do
  let(:parent_object) { FactoryBot.create(:parent_object, oid: 2_034_600) }
  let(:user) { FactoryBot.create(:user) }
  let(:batch_process) { FactoryBot.create(:batch_process, user: user) }
  let(:csv_upload) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "short_fixture_ids.csv")) }

  describe "with stubbed metadata cloud" do
    before do
      login_as(:user)
      batch_process.user_id = user.id
      stub_metadata_cloud("2034600")
      stub_metadata_cloud("2005512")
      stub_metadata_cloud("16414889")
      stub_metadata_cloud("14716192")
      stub_metadata_cloud("16854285")
    end

    it "has an a pending status" do
      expect(parent_object.notes_for_batch_process(batch_process.id).empty?).to be true
      expect(parent_object.status_for_batch_process(batch_process.id)).to eq "Pending"
    end

    describe "after running the background jobs" do
      around do |example|
        perform_enqueued_jobs do
          example.run
        end
      end

      before do
        stub_ptiffs_and_manifests
      end

      it "has an a complete status" do
        batch_process.file = csv_upload
        batch_process.save
        batch_process.run_callbacks :create
        po = ParentObject.find(14_716_192)
        expect(po.status_for_batch_process(batch_process.id)).to eq "Complete"
      end
    end
  end

  describe "with a parent object with a failure" do
    it "can reflect a failure" do
      allow(parent_object).to receive(:processing_event).and_return(
        IngestNotification.with(
          parent_object_id: parent_object.id,
          status: "failed",
          reason: "Fake failure 1",
          batch_process_id: batch_process.id
        ).deliver_all,
        IngestNotification.with(
          parent_object_id: parent_object.id,
          status: "failed",
          reason: "Fake failure 2",
          batch_process_id: batch_process.id
        ).deliver_all,
        IngestNotification.with(
          parent_object_id: parent_object.id,
          status: "processing-queued",
          reason: "Fake success",
          batch_process_id: batch_process.id
        ).deliver_all
      )
      parent_object
      batch_process.file = csv_upload
      batch_process.run_callbacks :create
      expect(parent_object.status_for_batch_process(batch_process.id)).to eq "Failed"
      expect(parent_object.latest_failure(batch_process.id)).to be_an_instance_of Hash
      expect(parent_object.latest_failure(batch_process.id)[:reason]).to eq "Fake failure 2"
      expect(parent_object.latest_failure(batch_process.id)[:time]).to be
    end
  end
end
