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
      stub_metadata_cloud("2046567")
      stub_metadata_cloud("16414889")
      stub_metadata_cloud("14716192")
      stub_metadata_cloud("16854285")
      stub_metadata_cloud("16172421")
    end

    it "has an in progress status" do
      expect(parent_object.status_for_batch_process(batch_process.id)).to eq "In progress - no failures"
    end
  end

  describe "with a parent object with a failure" do
    it "can reflect a failure" do
      allow(parent_object).to receive(:processing_event).and_return(
        IngestNotification.with(
          parent_object_id: parent_object.id,
          status: "failed",
          reason: "Fake failure",
          batch_process_id: batch_process.id
        ).deliver_all
      )
      parent_object
      batch_process.file = csv_upload
      batch_process.run_callbacks :create
      expect(parent_object.status_for_batch_process(batch_process.id)).to eq "Failed"
    end
  end
end
