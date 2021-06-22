# frozen_string_literal: true

require 'rails_helper'
RSpec::Matchers.define_negated_matcher :not_change, :change

RSpec.describe ChildObject, type: :model, prep_metadata_sources: true do
  let(:parent_object) { FactoryBot.create(:parent_object, oid: 2_004_628) }
  let(:child_object) { described_class.create(oid: "456789", parent_object: parent_object) }

  around do |example|
    access_master_mount = ENV["ACCESS_MASTER_MOUNT"]
    original_image_bucket = ENV["S3_SOURCE_BUCKET_NAME"]
    original_path_ocr = ENV['OCR_DOWNLOAD_BUCKET']
    ENV["ACCESS_MASTER_MOUNT"] = "s3"
    ENV["S3_SOURCE_BUCKET_NAME"] = "yale-test-image-samples"
    ENV['OCR_DOWNLOAD_BUCKET'] = "yul-dc-ocr-test"
    example.run
    ENV["S3_SOURCE_BUCKET_NAME"] = original_image_bucket
    ENV["ACCESS_MASTER_MOUNT"] = access_master_mount
    ENV['OCR_DOWNLOAD_BUCKET'] = original_path_ocr
  end

  describe "with a mounted directory for access masters" do
    around do |example|
      access_master_mount = ENV["ACCESS_MASTER_MOUNT"]
      ENV["ACCESS_MASTER_MOUNT"] = "/data"
      example.run
      ENV["ACCESS_MASTER_MOUNT"] = access_master_mount
    end
    before do
      stub_ptiffs
    end
    it "can return the access_master_path" do
      co_two = described_class.create(oid: "1080001", parent_object: parent_object)
      co_three = described_class.create(oid: "15239530", parent_object: parent_object)
      co_four = described_class.create(oid: "15239590", parent_object: parent_object)
      expect(child_object.access_master_path).to eq "/data/08/89/45/67/89/456789.tif"
      expect(co_two.access_master_path).to eq "/data/00/01/10/80/00/1080001.tif"
      expect(co_three.access_master_path).to eq "/data/03/30/15/23/95/30/15239530.tif"
      expect(co_four.access_master_path).to eq "/data/09/90/15/23/95/90/15239590.tif"
    end
  end

  describe "a child object that already has a remote ptiff" do
    around do |example|
      access_master_mount = ENV["ACCESS_MASTER_MOUNT"]
      ENV["ACCESS_MASTER_MOUNT"] = "s3"
      example.run
      ENV["ACCESS_MASTER_MOUNT"] = access_master_mount
    end
    let(:child_object) { described_class.create(oid: "456789", parent_object: parent_object, width: 200, height: 200) }
    before do
      stub_metadata_cloud("2004628")
      stub_request(:head, "https://yale-test-image-samples.s3.amazonaws.com/ptiffs/89/45/67/89/456789.tif")
        .to_return(status: 200, headers: { 'X-Amz-Meta-Width' => '100',
                                           'X-Amz-Meta-Height' => '200',
                                           'Content-Type' => 'image/tiff' })
      stub_request(:head, "https://yale-test-image-samples.s3.amazonaws.com/originals/89/45/67/89/456789.tif")
        .to_return(status: 200)
      parent_object
    end
    it "does not try to generate the ptiff if it already has height & width and remote ptiff already exists" do
      expect(child_object.pyramidal_tiff.valid?).to eq true
      expect(child_object.pyramidal_tiff).not_to receive(:convert_to_ptiff)
      expect(child_object.parent_object.ready_for_manifest?).to be true
    end

    describe "but does not have width and height in the database" do
      let(:parent_without_size) { FactoryBot.create(:parent_object, oid: 2_030_006) }
      before do
        stub_metadata_cloud("2030006")
        parent_without_size
        stub_ptiffs_and_manifests
        perform_enqueued_jobs
      end
      it "gets the width and height from the S3 metadata" do
        first_child_object = parent_without_size.child_objects.first
        expect(first_child_object.remote_metadata).to include(width: 2591, height: 4056)
      end
    end
  end

  describe "a child object that has generated a ptiff but has zero width and height" do
    before do
      stub_metadata_cloud("2004628")
      stub_request(:head, "https://yale-test-image-samples.s3.amazonaws.com/ptiffs/89/45/67/89/456789.tif")
        .to_return(status: 200)
      allow(child_object.pyramidal_tiff).to receive(:valid?).and_return(true)
      allow(child_object.pyramidal_tiff).to receive(:conversion_information).and_return(width: 0, height: 0)
      parent_object
    end

    it "does not save a width and height of 0" do
      expect do
        child_object.convert_to_ptiff
      end.to not_change(child_object, :height)
        .and not_change(child_object, :width)
    end
  end

  describe "when access master exist" do
    let(:child_object) { described_class.new }
    it "copy_to_access_master_pairtree notifies and returns true" do
      expect(child_object).to receive(:access_master_exists?).and_return(true).once
      expect(child_object).to receive(:processing_event).with("Not copied from Goobi package to access master pair-tree, already exists", 'access-master-exists').once
      child_object.copy_to_access_master_pairtree
    end
  end

  describe "a child object that has doesn't have a valid ptiff" do
    let(:child_object) { described_class.new }
    it "raises error on convert_to_ptiff" do
      # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(PyramidalTiff).to receive(:valid?).and_return(false)
      # rubocop:enable RSpec/AnyInstance
      expect do
        child_object.convert_to_ptiff
      end.to raise_error
    end
  end

  describe "a child object that has successfully generated a ptiff" do
    before do
      stub_metadata_cloud("2004628")
      stub_request(:head, "https://yale-test-image-samples.s3.amazonaws.com/ptiffs/89/45/67/89/456789.tif")
      .to_return(status: 200)
      allow(child_object.pyramidal_tiff).to receive(:valid?).and_return(true)
      allow(child_object.pyramidal_tiff).to receive(:conversion_information).and_return(width: 2591, height: 4056)
      parent_object
    end

    it "does not have a height and width before conversion" do
      expect(child_object.height).to be_nil
      expect(child_object.width).to be_nil
    end

    it "has a valid thumbnail url" do
      first_child_object = parent_object.child_objects.first
      expect(first_child_object.thumbnail_url).to eq "#{(ENV['IIIF_IMAGE_BASE_URL'])}/2/456789/full/!200,200/0/default.jpg"
    end

    it "has a valid height and width after conversion" do
      expect(child_object.height).to be_nil
      expect(child_object.width).to be_nil
      child_object.convert_to_ptiff
      expect(child_object.height).to be 4056
      expect(child_object.width).to be 2591
    end

    it "can access the parent object" do
      expect(child_object.parent_object).to be_instance_of ParentObject
    end

    it "can return a the remote access master path" do
      expect(child_object.remote_access_master_path).to eq "originals/89/45/67/89/456789.tif"
    end

    it "can return a the remote ptiff path" do
      expect(child_object.remote_ptiff_path).to eq "ptiffs/89/45/67/89/456789.tif"
    end

    it 'finds batch connections to the batch process' do
      user = FactoryBot.create(:user)
      batch_process = BatchProcess.new(oid: parent_object.oid, user: user)
      batch_process.batch_connections.build(connectable: child_object)
      batch_process.save!
      batch_connection = child_object.batch_connections
      expect(child_object.batch_connections_for(batch_process)).to eq(batch_connection)
    end

    describe "full text availability" do
      before do
        stub_metadata_cloud("2004628")
        stub_request(:head, "https://yul-dc-ocr-test.s3.amazonaws.com/fulltext/89/45/67/89/456789.txt")
        .to_return(status: 200, headers: { 'Content-Type' => 'text/plain' })
      end

      it "can return a the remote ocr path" do
        expect(child_object.remote_ocr_path).to eq "fulltext/89/45/67/89/456789.txt"
      end

      it "can determine if a child object has a txt file" do
        expect(child_object.remote_ocr).to eq(true)
      end
    end

    describe "with a cached width and height on s3", prep_admin_sets: true do
      before do
        stub_request(:head, "https://yale-test-image-samples.s3.amazonaws.com/ptiffs/89/45/67/89/456789.tif")
          .to_return(status: 200, headers: { 'X-Amz-Meta-Width' => '50',
                                             'X-Amz-Meta-Height' => '60',
                                             'Content-Type' => 'image/tiff' })
      end
      it "can receive width and height if they are cached" do
        # expect(StaticChildInfo).to receive(:size_for).and_return(width: 50, height: 60)
        expect(child_object).to receive(:remote_ptiff_exists?).and_return true
        expect(child_object.check_for_size_and_file).to be_a(Hash)
        expect(child_object.width).to eq(50)
        expect(child_object.height).to eq(60)
      end

      it "has relationship to parent admin set through parent property" do
        child_object.parent_object.admin_set = AdminSet.find_by_key("sml")
        child_object.parent_object.save!
        expect(child_object.reload.admin_set.key).to eq("sml")
      end

      it "has relationship to parent admin set through child property" do
        child_object.admin_set = AdminSet.find_by_key("sml")
        child_object.save!
        expect(child_object.parent_object.reload.admin_set.key).to eq("sml")
      end

      describe "with a cached width and height of 0" do
        before do
          stub_request(:head, "https://yale-test-image-samples.s3.amazonaws.com/ptiffs/89/45/67/89/456789.tif")
            .to_return(status: 200, headers: { 'X-Amz-Meta-Width' => '0',
                                               'X-Amz-Meta-Height' => '0',
                                               'Content-Type' => 'image/tiff' })
        end

        it "does not save a width and height of zero if they are cached" do
          expect(child_object.check_for_size_and_file).to eq(nil)
          expect(child_object.width).to eq(nil)
          expect(child_object.height).to eq(nil)
        end
      end
    end
  end
end
