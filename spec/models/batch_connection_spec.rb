# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BatchConnection, type: :model, prep_metadata_sources: true do
  let(:parent_object) { FactoryBot.create(:parent_object, oid: 2_034_600) }
  let(:user) { FactoryBot.create(:user) }
  let(:batch_process) { FactoryBot.create(:batch_process, user: user) }
  let(:csv_upload) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "short_fixture_ids.csv")) }

  it { is_expected.to have_db_column(:connectable_id).of_type(:integer) }
  it { is_expected.to have_db_column(:connectable_type).of_type(:string) }
  it { is_expected.to belong_to(:connectable) }

  it "can see a batch process and parent objects" do
    parent_object
    expect do
      batch_process.file = csv_upload
      batch_process.run_callbacks :create
    end.to change { batch_process.batch_connections.size }.from(0).to(5)
    expect(parent_object.batch_connections).not_to eq nil
    expect(parent_object.batch_connections.first).to eq batch_process.batch_connections.first
    expect(parent_object.batch_connections.first.child_object_count).to eq parent_object.child_object_count
    expect(parent_object.batch_connections.first.status).to eq "In progress - no failures"
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
      expect(parent_object.batch_connections.first.status).to eq "Failed"
    end
  end

  describe "with a deleted parent_object" do
    let(:batch_process_2) do
      FactoryBot.create(
        :batch_process,
        user: user,
        csv: File.open(fixture_path + '/small_short_fixture_ids.csv').read,
        file_name: "small_short_fixture_ids.csv",
        created_at: "2020-10-08 14:17:01"
      )
    end
    before do
      batch_process_2
      po = ParentObject.find(16_057_779)
      po.delete
    end

    it "can still see the details of the import" do
      bc = batch_process_2.batch_connections.where(connectable_id: 16_057_779).first
      expect(bc.status).to eq "Parent object deleted"
    end
  end
end
