# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BatchProcess, type: :model, prep_metadata_sources: true do
  subject(:batch_process) { described_class.new }
  let(:user) { FactoryBot.create(:user, uid: "mk2525") }
  let(:csv_upload) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "short_fixture_ids.csv")) }
  let(:csv_upload_with_source) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "short_fixture_ids_with_source.csv")) }
  let(:xml_upload) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path + '/goobi/metadata/30000317_20201203_140947/111860A_8394689_mets.xml')) }
  around do |example|
    original_path = ENV["GOOBI_MOUNT"]
    ENV["GOOBI_MOUNT"] = File.join("spec", "fixtures", "goobi", "metadata")
    example.run
    ENV["GOOBI_MOUNT"] = original_path
  end

  before do
    login_as(:user)
    batch_process.user_id = user.id
  end

  describe "with a parent object with a failure" do
    let(:batch_process_with_failure) { FactoryBot.create(:batch_process, user: user) }
    let(:parent_object) { FactoryBot.create(:parent_object, oid: 2_034_600) }
    let(:batch_connection) do
      FactoryBot.create(:batch_connection,
                        connectable: parent_object, batch_process: batch_process_with_failure)
    end

    it "can reflect a failure" do
      parent_object
      batch_process_with_failure.file = csv_upload
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
      parent_object.batch_connections.first.update_status!
      expect(parent_object.status_for_batch_process(batch_process_with_failure)).to eq "Failed"
      expect(parent_object.latest_failure(batch_process_with_failure)).to be_an_instance_of Hash
      expect(parent_object.latest_failure(batch_process_with_failure)[:reason]).to eq "Fake failure 2"
      expect(parent_object.latest_failure(batch_process_with_failure)[:time]).to be
      expect(batch_process_with_failure.batch_status).to eq "1 out of 5 parent objects have a failure."
    end
  end

  describe 'xml file import' do
    it "does not error out" do
      batch_process.file = xml_upload
      expect(batch_process).to be_valid
    end

    it "has an oid associated with it" do
      batch_process.file = xml_upload
      batch_process.save!
      expect(batch_process.oid).to eq 30_000_317
    end

    it "has a mets document associated with it that is not saved to the database" do
      batch_process.file = xml_upload
      expect(batch_process.mets_doc.valid_mets?).to eq true
    end

    it "evaluates a valid METs file as valid" do
      batch_process.file = xml_upload
      expect(batch_process.mets_xml).to be_present
      expect(batch_process).to be_valid
    end

    describe "running the background jobs" do
      before do
        stub_metadata_cloud("V-30000317", "ils")
      end

      it "creates a new parent object" do
        expect do
          batch_process.file = xml_upload
          batch_process.save
        end.to change { ParentObject.count }.from(0).to(1)
      end

      it "does not try to get Ladybird data for new Goobi objects" do
        batch_process.file = xml_upload
        batch_process.save
        po = ParentObject.find(30_000_317)
        expect(po.bib).to eq "8394689"
      end
    end
  end

  describe "with the metadata cloud mocked" do
    before do
      stub_metadata_cloud("2034600")
      stub_metadata_cloud("2005512")
      stub_metadata_cloud("2046567")
      stub_metadata_cloud("16414889")
      stub_metadata_cloud("14716192")
      stub_metadata_cloud("16854285")
      stub_metadata_cloud("16172421")
    end

    describe "batch import" do
      it "includes the originating user NETid" do
        batch_process.user_id = user.id
        expect(batch_process.user.uid).to eq "mk2525"
      end
    end

    context "creating a ParentObject from an import" do
      before do
        stub_metadata_cloud("16371253")
      end
      it "can create a parent_object from an array of oids" do
        expect do
          batch_process.save
          batch_process.create_parent_objects_from_oids(["16371253"], ["ladybird"])
        end.to change { ParentObject.count }.from(0).to(1)
      end
    end

    describe "csv file import" do
      it "accepts a csv file as a virtual attribute and read the csv into the csv property" do
        batch_process.file = csv_upload
        batch_process.user_id = user.id
        expect(batch_process.csv).to be_present
        expect(batch_process).to be_valid
        expect(batch_process.file_name).to eq "short_fixture_ids.csv"
      end
      #
      # it "does not accept non csv files" do
      #   batch_process.file = File.new(Rails.root.join('public', 'favicon.ico'))
      #   expect(batch_process).not_to be_valid
      #   expect(batch_process.csv).to be_blank
      # end

      it "can refresh the ParentObjects from the MetadataCloud" do
        expect(ParentObject.count).to eq 0
        expect do
          batch_process.file = csv_upload
          batch_process.save
        end.to change { batch_process.batch_connections.size }.from(0).to(5)

        expect(ParentObject.count).to eq 5
      end

      it "can identify the metadata source" do
        batch_process.file = csv_upload_with_source
        batch_process.save
        expect(ParentObject.first.authoritative_metadata_source_id).to eq 1
        expect(ParentObject.second.authoritative_metadata_source_id).to eq 2
        expect(ParentObject.third.authoritative_metadata_source_id).to eq 3
        expect(ParentObject.fourth.authoritative_metadata_source_id).to eq 2
        expect(ParentObject.fifth.authoritative_metadata_source_id).to eq 1
      end

      it 'defaults to ladybird if no metadata source is provided' do
        batch_process.file = csv_upload_with_source
        batch_process.save
        expect(ParentObject.last.authoritative_metadata_source_id).to eq 1
      end

      it 'has a status for the batch process' do
        batch_process.file = csv_upload_with_source
        batch_process.save
        expect(batch_process.batch_status).to eq "Batch in progress - no failures"
      end

      describe "with a parent object that had been previously created" do
        let(:parent_object) { FactoryBot.create(:parent_object, oid: 2_034_600) }
        before do
          stub_ptiffs_and_manifests
        end

        around do |example|
          perform_enqueued_jobs do
            example.run
          end
        end

        it "assigns the batch_process to an already-existing parent object" do
          parent_object
          po = ParentObject.find(2_034_600)
          expect(po.visibility).to eq "Public"
          batch_process.file = csv_upload
          batch_process.save
          child = po.child_objects.first
          notes = child.notes_for_batch_process(batch_process)
          expect(notes).to include("ptiff-ready")
          expect(notes).to include("ptiff-queued")
          expect(child.status_for_batch_process(batch_process)).to eq "Complete"
          expect(po.status_for_batch_process(batch_process)).to eq "Complete"
          expect(po.batch_processes.first).to eq batch_process
          expect(po.visibility).to eq "Public"
          po_two = ParentObject.find(2_005_512)
          expect(po_two.visibility).to eq "Public"
        end
      end
    end
  end
end
