# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BatchProcess, type: :model, prep_metadata_sources: true do
  subject(:batch_process) { described_class.new }
  let(:user) { FactoryBot.create(:user, uid: "mk2525") }
  let(:csv_upload) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "short_fixture_ids.csv")) }
  let(:csv_upload_with_source) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "short_fixture_ids_with_source.csv")) }
  let(:xml_upload) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path + '/goobi/metadata/30000317_20201203_140947/111860A_8394689_mets.xml')) }
  let(:xml_upload_two) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path + '/goobi/metadata/30000401_20201204_193140/IkSw55739ve_RA_mets.xml')) }

  around do |example|
    original_image_bucket = ENV["S3_SOURCE_BUCKET_NAME"]
    original_access_master_mount = ENV["ACCESS_MASTER_MOUNT"]
    ENV["S3_SOURCE_BUCKET_NAME"] = "yale-test-image-samples"
    ENV["ACCESS_MASTER_MOUNT"] = File.join("spec", "fixtures", "images", "access_masters")
    perform_enqueued_jobs do
      example.run
    end
    ENV["S3_SOURCE_BUCKET_NAME"] = original_image_bucket
    ENV["ACCESS_MASTER_MOUNT"] = original_access_master_mount
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
      parent_object.batch_connections.first.update_status!
      expect(parent_object.status_for_batch_process(batch_process_with_failure)).to eq "Failed"
      expect(parent_object.latest_failure(batch_process_with_failure)).to be_an_instance_of Hash
      expect(parent_object.latest_failure(batch_process_with_failure)[:reason]).to eq "Fake failure 2"
      expect(parent_object.latest_failure(batch_process_with_failure)[:time]).to be
      expect(batch_process_with_failure.batch_status).to eq "Batch failed"
    end
  end

  describe 'xml file import' do
    before do
      stub_metadata_cloud("V-30000401", "ils")
      stub_ptiffs_and_manifests
    end
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
        stub_pdfs
        stub_request(:put, "https://yale-test-image-samples.s3.amazonaws.com/ptiffs/02/30/00/04/02/30000402.tif").to_return(status: 200)
        stub_request(:put, "https://yale-test-image-samples.s3.amazonaws.com/ptiffs/03/30/00/04/03/30000403.tif").to_return(status: 200)
        stub_request(:put, "https://yale-test-image-samples.s3.amazonaws.com/ptiffs/04/30/00/04/04/30000404.tif").to_return(status: 200)
        stub_request(:head, "https://yale-test-image-samples.s3.amazonaws.com/ptiffs/02/30/00/04/02/30000402.tif").to_return(status: 200)
        stub_request(:head, "https://yale-test-image-samples.s3.amazonaws.com/ptiffs/03/30/00/04/03/30000403.tif").to_return(status: 200)
        stub_request(:head, "https://yale-test-image-samples.s3.amazonaws.com/ptiffs/04/30/00/04/04/30000404.tif").to_return(status: 200)
      end

      around do |example|
        perform_enqueued_jobs do
          example.run
        end
      end

      let(:logger_mock) { instance_double("Rails.logger").as_null_object }
      # Doing one large test here, because with copying images, etc., it is an expensive one
      it "creates a parent object with the expected values and child objects with expected values" do
        # TODO: TURN THIS BACK ON FOR GOOBI!!! - Remove the following two lines - pending and rails logger mock
        pending("Copying the goobi files to the access master pair-tree in the GeneratePtiffJob")
        allow(Rails.logger).to receive(:debug) { :logger_mock }
        expect(File.exist?("spec/fixtures/images/access_masters/00/02/30/00/04/02/30000402.tif")).to be false
        expect(File.exist?("spec/fixtures/images/access_masters/00/03/30/00/04/03/30000403.tif")).to be false
        expect(File.exist?("spec/fixtures/images/access_masters/00/04/30/00/04/04/30000404.tif")).to be false
        expect do
          batch_process.file = xml_upload_two
          batch_process.save
        end.to change { ParentObject.count }.from(0).to(1)
           .and change { ChildObject.count }.from(0).to(3)
        po = ParentObject.find(30_000_401)
        co = ChildObject.find(30_000_404)
        # parent object expectations
        expect(po.child_object_count).to eq 3
        expect(po.visibility).to eq "Public"
        expect(po.rights_statement).to include "The use of this image may be subject to"
        expect(po.authoritative_metadata_source.display_name).to eq "Voyager"
        expect(po.voyager_json.present?).to be_truthy
        expect(po.bib).to eq "1188135"
        expect(po.holding).to eq "1330141"
        expect(po.item).to eq "0"
        expect(po.barcode).to eq nil
        expect(po.viewing_direction).to eq "left-to-right"
        expect(po.display_layout).to eq "individuals"
        expect(po.representative_child_oid).to eq 30_000_403
        # child object expectations
        expect(co.checksum).to eq "c314697a5b0fd444e26e7c12a1d8d487545dacfc"
        expect(co.mets_access_master_path).to eq "/home/app/webapp/spec/fixtures/goobi/metadata/30000401_20201204_193140/IkSw55739ve_RA_media/30000404.tif"
        expect(File.exist?("spec/fixtures/images/access_masters/00/02/30/00/04/02/30000402.tif")).to be true
        expect(File.exist?("spec/fixtures/images/access_masters/00/03/30/00/04/03/30000403.tif")).to be true
        expect(File.exist?("spec/fixtures/images/access_masters/00/04/30/00/04/04/30000404.tif")).to be true
        expect(co.ptiff_conversion_at.present?).to be_truthy
        File.delete("spec/fixtures/images/access_masters/00/02/30/00/04/02/30000402.tif")
        File.delete("spec/fixtures/images/access_masters/00/03/30/00/04/03/30000403.tif")
        File.delete("spec/fixtures/images/access_masters/00/04/30/00/04/04/30000404.tif")
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
      stub_metadata_cloud("30000016189097")
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
      before do
        stub_ptiffs_and_manifests
      end
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
        expect(batch_process.batch_status).to eq "4 out of 6 parent objects are in progress."
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
