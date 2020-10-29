# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BatchProcess, type: :model, prep_metadata_sources: true do
  subject(:batch_process) { described_class.new }
  let(:user) { FactoryBot.create(:user, uid: "mk2525") }
  let(:csv_upload) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "short_fixture_ids.csv")) }
  let(:csv_upload_with_source) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "short_fixture_ids_with_source.csv")) }
  let(:xml_upload) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path + '/goobi/metadata/16172421/meta.xml')) }
  around do |example|
    original_path = ENV["GOOBI_MOUNT"]
    ENV["GOOBI_MOUNT"] = File.join("spec", "fixtures", "goobi", "metadata")
    example.run
    ENV["GOOBI_MOUNT"] = original_path
  end

  before do
    login_as(:user)
    batch_process.user_id = user.id
    stub_metadata_cloud("2034600")
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
      expect(ParentObject.count).to eq 0
      batch_process.save
      batch_process.create_parent_objects_from_oids(["16371253"], ["ladybird"])
      expect(ParentObject.count).to eq 1
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
  end

  describe 'xml file import' do
    it "does not error out" do
      batch_process.file = xml_upload
      expect(batch_process).to be_valid
    end

    it "has an oid associated with it" do
      batch_process.file = xml_upload
      batch_process.save!
      expect(batch_process.oid).to eq 16_172_421
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

    it "can refresh the ParentObjects from the MetadataCloud" do
      expect(ParentObject.count).to eq 0
      batch_process.file = xml_upload
      batch_process.save
      expect(ParentObject.count).to eq 1
    end
  end
end
