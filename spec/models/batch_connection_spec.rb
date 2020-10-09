# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BatchConnection, type: :model, prep_metadata_sources: true do
  let(:parent_object) { FactoryBot.create(:parent_object, oid: 2_034_600) }
  let(:batch_process) { FactoryBot.create(:batch_process) }
  let(:csv_upload) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "short_fixture_ids.csv")) }

  it { is_expected.to have_db_column(:connection_id).of_type(:integer) }
  it { is_expected.to have_db_column(:connection_type).of_type(:string) }
  it { is_expected.to belong_to(:connection) }

  it "can see a batch process and parent objects" do
    parent_object
    expect do
      batch_process.file = csv_upload
      batch_process.run_callbacks :create
    end.to change { batch_process.batch_connections.size }.from(0).to(5)
    expect(parent_object.batch_connections.first).to eq batch_process.batch_connections.first
  end
end
