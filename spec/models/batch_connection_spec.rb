# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BatchConnection, type: :model, prep_metadata_sources: true do
  # let(:parent_object) { FactoryBot.create(:parent_object, oid: 2_034_600) }
  let(:user) { FactoryBot.create(:user) }
  let(:batch_process) { FactoryBot.create(:batch_process, user: user) }
  let(:csv_upload) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "short_fixture_ids.csv")) }

  it { is_expected.to have_db_column(:connectable_id).of_type(:integer) }
  it { is_expected.to have_db_column(:connectable_type).of_type(:string) }
  it { is_expected.to belong_to(:connectable) }

  it "can see a batch process and parent objects" do
    expect do
      batch_process.file = csv_upload
      batch_process.save!
      batch_process.run_callbacks :create
    end.to change { batch_process.batch_connections.size }.from(0).to(5)
    po = ParentObject.find(2_034_600)
    expect(po.batch_connections).not_to eq nil
    expect(po.batch_connections.first).to eq batch_process.batch_connections.first
    expect(po.batch_connections.first.connectable.child_object_count).to eq po.child_object_count
  end

  describe "running the background job" do
    around do |example|
      perform_enqueued_jobs do
        example.run
      end
    end

    before do
      stub_ptiffs_and_manifests
      stub_metadata_cloud("2004628")
      stub_metadata_cloud("16414889")
      stub_metadata_cloud("14716192")
      stub_metadata_cloud("16854285")
      stub_metadata_cloud("16057779")
    end
    it "gets a complete status when a complete notification is emitted" do
      batch_process.file = csv_upload
      batch_process.run_callbacks :create
      po = ParentObject.find(2_034_600)
      expect(po.status_for_batch_process(batch_process.id)).to eq "Complete"
      batch_connection = batch_process.batch_connections.detect { |b| b.connectable == po }
      expect(batch_connection.status).to eq "Complete"
    end
  end
end
