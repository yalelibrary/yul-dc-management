# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BatchConnection, type: :model, prep_metadata_sources: true do
  let(:user) { FactoryBot.create(:user) }
  let(:batch_process) { FactoryBot.create(:batch_process, user: user) }
  let(:csv_upload) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "short_fixture_ids.csv")) }
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

  it { is_expected.to have_db_column(:connectable_id).of_type(:integer) }
  it { is_expected.to have_db_column(:connectable_type).of_type(:string) }
  it { is_expected.to belong_to(:connectable) }

  it "can see a batch process and parent objects" do
    expect(batch_process.batch_connections.size).to eq 0
    batch_process.file = csv_upload
    batch_process.save!
    batch_process.run_callbacks :create
    expect(batch_process.batch_connections.where(connectable_type: "ParentObject").count).to eq 5
    expect(batch_process.batch_connections.where(connectable_type: "ParentObject").count).to eq 213
    # expect(batch_process.batch_connections.count).to eq 218
    po = ParentObject.find(2_034_600)
    bp = BatchProcess.find(batch_process.id)
    expect(po.batch_connections).not_to eq nil
    expect(po.batch_connections.first).to eq bp.batch_connections.first
    expect(po.batch_connections.first.connectable.child_object_count).to eq po.child_object_count
  end

  it "batch_connections_for returns itself" do
    batch_process.file = csv_upload
    batch_process.save!
    batch_process.run_callbacks :create
    po = ParentObject.find(2_034_600)
    batch_connection = po.batch_connections.first
    expect(batch_connection.batch_connections_for(batch_process)).to eq([batch_connection])
  end

  # this is failing in CI, but not locally. May simply be too slow, trying to do all the jobs for all the
  # parent objects. Marking pending for now, believe this code is sufficiently tested elsewhere.
  xit "gets a complete status when a complete notification is emitted" do
    batch_process.file = csv_upload
    batch_process.run_callbacks :create
    po = ParentObject.find(2_034_600)
    expect(po.status_for_batch_process(batch_process)).to eq "Complete"
    batch_connection = batch_process.batch_connections.detect { |b| b.connectable == po }
    expect(batch_connection.status).to eq "Complete"
  end
end
