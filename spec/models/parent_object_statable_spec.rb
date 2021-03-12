# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ParentObject, type: :model, prep_metadata_sources: true, prep_admin_sets: true do
  let(:parent_object) { FactoryBot.create(:parent_object, oid: 2_034_600) }
  let(:user) { FactoryBot.create(:user) }
  let(:batch_process) { FactoryBot.create(:batch_process, user: user) }
  let(:csv_upload) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "short_fixture_ids.csv")) }
  let(:bad_oid_upload) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "bad_oid.csv")) }

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

    context "with no metadatacloud record" do
      let(:batch_process_with_failure) { FactoryBot.create(:batch_process, user: user) }
      let(:parent_object) { FactoryBot.create(:parent_object, oid: 16_609_818) }
      let(:batch_connection) do
        FactoryBot.create(:batch_connection,
                          connectable: parent_object, batch_process: batch_process_with_failure)
      end

      before do
        stub_request(:get, "https://#{ENV['SAMPLE_BUCKET']}.s3.amazonaws.com/ladybird/#{parent_object.oid}.json")
          .to_return(status: 400, body: File.open(File.join(fixture_path, "metadata_cloud_no_record.json")))
      end

      around do |example|
        perform_enqueued_jobs do
          example.run
        end
      end

      it "does not continue with the background jobs if that particular oid does not have a record" do
        parent_object
        batch_process_with_failure.file = bad_oid_upload
        batch_process_with_failure.save
        batch_process_with_failure.run_callbacks :create
        batch_process_with_failure.batch_connections.first.update_status!
        expect(parent_object.status_for_batch_process(batch_process_with_failure)).to eq "Failed"
        expect(parent_object.notes_for_batch_process(batch_process_with_failure)).not_to include "metadata-fetched"
      end
    end

    it "has an a pending status" do
      expect(parent_object.notes_for_batch_process(batch_process).empty?).to be true
      expect(parent_object.status_for_batch_process(batch_process)).to eq "Pending"
      expect(parent_object.duration_for_batch_process(batch_process)).to eq "n/a"
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
        expect(po.status_for_batch_process(batch_process)).to eq "Complete"
        expect(po.duration_for_batch_process(batch_process)).not_to eq "n/a"
        expect(po.duration_for_batch_process(batch_process)).to be_an_instance_of Float
      end
    end
  end

  describe "with a parent object with a failure" do
    let(:batch_process_with_failure) { FactoryBot.create(:batch_process, user: user) }
    let(:parent_object) { FactoryBot.create(:parent_object, oid: 2_034_600) }
    let(:batch_connection) do
      FactoryBot.create(:batch_connection,
                        connectable: parent_object, batch_process: batch_process_with_failure)
    end
    # rubocop:disable RSpec/AnyInstance
    before do
      allow_any_instance_of(ChildObject).to receive(:remote_ptiff_exists?).and_return(false)
      allow_any_instance_of(ChildObject).to receive(:convert_to_ptiff!).and_return(true)
      allow_any_instance_of(PyramidalTiff).to receive(:valid?).and_return(false)
    end
    # rubocop:enable RSpec/AnyInstance

    around do |example|
      perform_enqueued_jobs do
        example.run
      end
    end

    it "can reflect a failure" do
      parent_object
      batch_process_with_failure.file = csv_upload
      batch_process_with_failure.save
      batch_process_with_failure.run_callbacks :create
      allow(parent_object).to receive(:processing_event).and_return(
        IngestEvent.create(
          status: "failed",
          reason: "Fake failure 1",
          batch_connection: parent_object.batch_connections.first
        ),
        IngestEvent.create(
          status: "failed",
          reason: "Fake failure 2",
          batch_connection: parent_object.batch_connections.first
        ),
        IngestEvent.create(
          status: "processing-queued",
          reason: "Fake success",
          batch_connection: parent_object.batch_connections.first
        )
      )

      batch_process_with_failure.batch_connections.first.update_status!
      expect(parent_object.status_for_batch_process(batch_process_with_failure)).to eq "Failed"
      expect(parent_object.latest_failure(batch_process_with_failure)).to be_an_instance_of Hash
      expect(parent_object.latest_failure(batch_process_with_failure)[:reason]).to eq "Fake failure 2"
      expect(parent_object.latest_failure(batch_process_with_failure)[:time]).to be
    end
  end
end
