# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BatchProcess, type: :model, prep_metadata_sources: true do
  subject(:batch_process) { described_class.new }
  let(:user) { FactoryBot.create(:user, uid: "mk2525") }
  let(:csv_upload) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "short_fixture_ids.csv")) }
  let(:csv_upload_with_source) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "short_fixture_ids_with_source.csv")) }
  let(:xml_upload) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path + '/goobi/metadata/30000317_20201203_140947/111860A_8394689_mets.xml')) }
  let(:xml_upload_two) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path + '/goobi/metadata/30000401_20201204_193140/IkSw55739ve_RA_mets.xml')) }
  let(:aspace_xml_upload) { Rack::Test::UploadedFile.new("spec/fixtures/goobi/metadata/30000317_20201203_140947/good_aspace.xml") }

  around do |example|
    original_image_bucket = ENV["S3_SOURCE_BUCKET_NAME"]
    original_access_master_mount = ENV["ACCESS_MASTER_MOUNT"]
    ENV["S3_SOURCE_BUCKET_NAME"] = "yale-test-image-samples"
    ENV["ACCESS_MASTER_MOUNT"] = File.join("spec", "fixtures", "images", "access_masters")
    example.run
    ENV["S3_SOURCE_BUCKET_NAME"] = original_image_bucket
    ENV["ACCESS_MASTER_MOUNT"] = original_access_master_mount
  end

  before do
    login_as(:user)
    batch_process.user_id = user.id
  end

  describe "not running the background jobs" do
    it "creates a parent object with values only from the METs document" do
      expect(batch_process.batch_action).to eq "create parent objects"
      expect do
        batch_process.file = xml_upload_two
        batch_process.save!
      end.to change { ParentObject.count }.from(0).to(1)
      po = ParentObject.find(30_000_401)
      expect(po.visibility).to eq "Public"
      expect(po.rights_statement).to include "The use of this image may be subject to"
      expect(po.authoritative_metadata_source.display_name).to eq "Voyager"
      expect(po.voyager_json.present?).to be_falsy
      expect(po.bib).to eq "1188135"
      expect(po.holding).to eq "1330141"
      expect(po.item).to eq nil
      expect(po.barcode).to eq nil
      expect(po.viewing_direction).to eq "left-to-right"
      expect(po.display_layout).to eq "individuals"
      expect(po.representative_child_oid).to eq 30_000_403
      expect(po.metadata_cloud_url).to eq "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/#{MetadataSource.metadata_cloud_version}/ils/holding/1330141?bib=1188135"
    end

    it "creates a parent object with barcode from the METs document" do
      batch_process.file = xml_upload
      batch_process.save!
      po = ParentObject.find(30_000_317)
      expect(po.barcode).to eq "39002091118928"
    end

    it "creates a parent object with aspace uri from the METs document" do
      batch_process.file = aspace_xml_upload
      batch_process.save!
      po = ParentObject.find(30_000_557)
      expect(po.aspace_uri).to eq "/repositories/11/archival_objects/329771"
      expect(po.metadata_cloud_url).to eq "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/#{MetadataSource.metadata_cloud_version}/aspace/repositories/11/archival_objects/329771"
    end
  end

  describe "running the background jobs" do
    around do |example|
      perform_enqueued_jobs do
        example.run
      end
    end

    before do
      # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(PyramidalTiff).to receive(:valid?).and_return(true)
      allow_any_instance_of(PyramidalTiff).to receive(:conversion_information).and_return(width: 5, height: 5)
      allow_any_instance_of(ChildObject).to receive(:remote_ptiff_exists?).and_return(false)
      allow_any_instance_of(PdfRepresentable).to receive(:generate_pdf).and_return(nil)
      # rubocop:enable RSpec/AnyInstance
    end

    describe "with a parent object with a failure" do
      let(:batch_process_with_failure) { FactoryBot.create(:batch_process, user: user) }
      let(:parent_object) { FactoryBot.create(:parent_object, oid: 2_034_600) }
      let(:batch_connection) do
        FactoryBot.create(:batch_connection,
                          connectable: parent_object, batch_process: batch_process_with_failure)
      end
      # rubocop:disable RSpec/AnyInstance
      it "can reflect a failure" do
        batch_process_with_failure.file = csv_upload
        batch_process_with_failure.save
        batch_process_with_failure.run_callbacks :create
        allow_any_instance_of(BatchProcess).to receive(:status_hash).and_return(
          complete: 0,
          in_progress: 0,
          failed: 5,
          unknown: 0,
          total: 5
        )
        expect(batch_process_with_failure.batch_status).to eq "Batch failed"
      end
      # rubocop:enable RSpec/AnyInstance
    end

    describe 'recreating child oid ptiffs' do
      let(:admin_set) { FactoryBot.create(:admin_set) }
      let(:role) { FactoryBot.create(:role, name: editor) }
      let(:parent_object) { ParentObject.find(30_000_317) }
      let(:child_object) { parent_object.child_objects.first }

      before do
        stub_metadata_cloud("V-30000317", "ils")
        stub_ptiffs_and_manifests
        batch_process.file = xml_upload
        batch_process.save!
        parent_object.admin_set_id = admin_set.id
        parent_object.save!
      end

      it 'calls the configure_parent_object method' do
        parents = Set[]
        expect do
          batch_process.configure_parent_object(child_object, parents)
        end.to change { IngestEvent.count }.by(1)
        expect(parents.size).to equal(1)
        expect(parent_object.batch_processes).to include(batch_process)
      end

      it 'calls the user_update_permission method and returns false if the user does not have editor permissions on the admin set' do
        parents = Set[]
        batch_process.configure_parent_object(child_object, parents)
        batch_process.attach_item(child_object)
        expect do
          batch_process.user_update_permission(child_object, child_object.parent_object)
        end.to change { IngestEvent.count }.by(3)

        expect(batch_process.user_update_permission(child_object, parent_object)).to eq(false)
      end

      it 'calls the user_update_permission method and returns true if the user does have editor permission on the admin set' do
        user.add_role(:editor, admin_set)
        expect(batch_process.user_update_permission(child_object, parent_object)).to eq(true)
      end
    end

    describe 'xml file import' do
      before do
        stub_metadata_cloud("V-30000401", "ils")
        stub_metadata_cloud("2004628", "ladybird")
        stub_metadata_cloud("2030006", "ladybird")
        stub_metadata_cloud("2034600", "ladybird")
        stub_metadata_cloud("16057779", "ladybird")
        stub_ptiffs_and_manifests
      end
      it "does not error out" do
        batch_process.file = xml_upload
        expect(batch_process).to be_valid
      end

      describe "importing a csv" do
        around do |example|
          perform_enqueued_jobs do
            example.run
          end
        end

        it "creates batch connections for all parent and child objects in the batch process" do
          expect(ParentObject.count).to eq 0
          expect(ChildObject.count).to eq 0
          expect do
            batch_process.file = Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "small_short_fixture_ids.csv"))
            batch_process.save
          end.to change { batch_process.batch_connections.count }.from(0).to(11)
          expect(ParentObject.count).to eq 4
          expect(ChildObject.count).to eq 7
          expect(batch_process.batch_connections.where(connectable_type: "ParentObject").count).to eq(4)
          expect(batch_process.batch_connections.where(connectable_type: "ChildObject").count).to eq(7)
        end
      end

      it "can identify the metadata source" do
        batch_process.file = csv_upload_with_source
        batch_process.save!
        expect(ParentObject.find(2_034_600).authoritative_metadata_source_id).to eq 1
        expect(ParentObject.find(2_030_006).authoritative_metadata_source_id).to eq 2
        expect(ParentObject.find(2_012_036).authoritative_metadata_source_id).to eq 3
        expect(ParentObject.find(16_414_889).authoritative_metadata_source_id).to eq 2
        expect(ParentObject.find(16_854_285).authoritative_metadata_source_id).to eq 1
      end

      it "has an oid associated with it" do
        batch_process.file = xml_upload
        batch_process.save!
        expect(batch_process.oid).to eq 30_000_317
        # TODO: This test is not testing the file copy, update so that it doesn't copy file
        file_path = "spec/fixtures/images/access_masters/01/18/30/00/03/18/30000318.tif"
        File.delete("spec/fixtures/images/access_masters/01/18/30/00/03/18/30000318.tif") if File.exist?(file_path)
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

        # Doing one large test here, because with copying images, etc., it is an expensive one
        it "creates a parent object with the expected values and child objects with expected values" do
          expect(File.exist?("spec/fixtures/images/access_masters/00/02/30/00/04/02/30000402.tif")).to be false
          expect(File.exist?("spec/fixtures/images/access_masters/00/03/30/00/04/03/30000403.tif")).to be false
          expect(File.exist?("spec/fixtures/images/access_masters/00/04/30/00/04/04/30000404.tif")).to be false
          expect(batch_process.batch_action).to eq "create parent objects"
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
          expect(po.item).to eq nil
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
        stub_metadata_cloud("V-2030006", "ils")
        stub_metadata_cloud("V-16414889", "ils")
        stub_metadata_cloud("AS-2012036", "aspace")
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
          end.to change { batch_process.batch_connections.size }.from(0).to(218)

          expect(ParentObject.count).to eq 5
        end

        it "can identify the metadata source" do
          batch_process.file = csv_upload_with_source
          batch_process.save
          expect(ParentObject.find(2_034_600).authoritative_metadata_source_id).to eq 1
          expect(ParentObject.find(2_030_006).authoritative_metadata_source_id).to eq 2
          expect(ParentObject.find(2_012_036).authoritative_metadata_source_id).to eq 3
          expect(ParentObject.find(16_414_889).authoritative_metadata_source_id).to eq 2
          expect(ParentObject.find(16_854_285).authoritative_metadata_source_id).to eq 1
        end

        it 'defaults to ladybird if no metadata source is provided' do
          batch_process.file = csv_upload_with_source
          batch_process.save
          expect(ParentObject.last.authoritative_metadata_source_id).to eq 1
        end

        it 'has a status for the batch process' do
          possible_statuses = [
            %r{\d out of \d parent objects have a failure.},
            %r{\d out of \d parent objects are in progress.},
            "Batch status unknown",
            "Batch in progress - no failures",
            "Batch complete",
            "Batch failed"
          ]

          batch_process.file = csv_upload_with_source
          batch_process.save
          expect(possible_statuses.any? do |status|
            status.match? batch_process.batch_status
          end).to be_truthy
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
end
