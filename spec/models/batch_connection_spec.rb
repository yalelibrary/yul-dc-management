# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BatchConnection, type: :model, prep_metadata_sources: true do
  let(:parent_object) { FactoryBot.build(:parent_object, oid: 2_034_600) }
  let(:user) { FactoryBot.create(:user) }
  let(:batch_process) { FactoryBot.create(:batch_process, user: user) }
  let(:csv_upload) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "short_fixture_ids.csv")) }

  it { is_expected.to have_db_column(:connectable_id).of_type(:integer) }
  it { is_expected.to have_db_column(:connectable_type).of_type(:string) }
  it { is_expected.to belong_to(:connectable) }

  around do |example|
    perform_enqueued_jobs do
      example.run
    end
  end

  it "can see a batch process and parent objects" do
    parent_object
    expect do
      batch_process.file = csv_upload
      batch_process.run_callbacks :create
    end.to change { batch_process.batch_connections.size }.from(0).to(5)
    expect(parent_object.batch_connections).not_to eq nil
    expect(parent_object.batch_connections.first).to eq batch_process.batch_connections.first
    expect(parent_object.batch_connections.first.connectable.child_object_count).to eq parent_object.child_object_count
  end

  it "gets a failed status when a failed notification is emitted" do
    batch_process.file = csv_upload
    batch_process.run_callbacks :create
    po = ParentObject.find(2034600)
    expect(po.status_for_batch_process(batch_process.id)).to eq "Failed"
    batch_connection = batch_process.batch_connections.detect { |b| b.connectable == po }
    expect(batch_connection.status).to eq "Failed"
  end
end
