# frozen_string_literal: true
require "rails_helper"

RSpec.describe Delayable, prep_metadata_sources: true, prep_admin_sets: true do
  let(:user) { FactoryBot.create(:user) }
  let(:batch_process) { BatchProcess.create(user_id: user.id) }
  let(:parent_object) { FactoryBot.build(:parent_object, oid: '16685691') }
  let(:csv_upload) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "short_fixture_ids.csv")) }

  around do |example|
    perform_enqueued_jobs do
      example.run
    end
  end

  
  describe "delayed_jobs" do

    before do
      stub_metadata_cloud("16685691")
      stub_ptiffs_and_manifests
    end

    it "returns delayed jobs associated with the parent object" do
      batch_process.setup_for_background_jobs(parent_object, 'ladybird')
      # batch_connection = batch_process.batch_connections.build(connectable: parent_object)
      # batch_connection.save
      # parent_object.current_batch_process = batch_process
      # parent_object.current_batch_connection = batch_connection
      # byebug
      parent_object.save
      # parent_object.setup_metadata_job
      # SetupMetadataJob.perform(parent_object, batch_process, batch_connection)
      byebug
      # expect(parent_)

    end
  end
end
