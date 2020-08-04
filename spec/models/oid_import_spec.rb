# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OidImport, type: :model, prep_metadata_sources: true do
  subject(:oid_import) { described_class.new }
  let(:metadata_cloud_response_body_1) { File.open(File.join(fixture_path, "ladybird", "2034600.json")).read }
  let(:metadata_cloud_response_body_2) { File.open(File.join(fixture_path, "ladybird", "2046567.json")).read }
  let(:metadata_cloud_response_body_3) { File.open(File.join(fixture_path, "ladybird", "16414889.json")).read }
  let(:metadata_cloud_response_body_4) { File.open(File.join(fixture_path, "ladybird", "14716192.json")).read }
  let(:metadata_cloud_response_body_5) { File.open(File.join(fixture_path, "ladybird", "16854285.json")).read }

  before do
    stub_request(:get, "https://yul-development-samples.s3.amazonaws.com/ladybird/2034600.json")
      .to_return(status: 200, body: metadata_cloud_response_body_1)
    stub_request(:get, "https://yul-development-samples.s3.amazonaws.com/ladybird/2046567.json")
      .to_return(status: 200, body: metadata_cloud_response_body_2)
    stub_request(:get, "https://yul-development-samples.s3.amazonaws.com/ladybird/16414889.json")
      .to_return(status: 200, body: metadata_cloud_response_body_3)
    stub_request(:get, "https://yul-development-samples.s3.amazonaws.com/ladybird/14716192.json")
      .to_return(status: 200, body: metadata_cloud_response_body_4)
    stub_request(:get, "https://yul-development-samples.s3.amazonaws.com/ladybird/16854285.json")
      .to_return(status: 200, body: metadata_cloud_response_body_5)
  end

  describe "csv file import" do
    it "requires no attributes" do
      expect(OidImport.new).to be_valid
    end

    it "accepts a csv file as a virtual attribute and read the csv into the csv property" do
      oid_import.file = File.new(fixture_path + '/short_fixture_ids.csv')
      expect(oid_import.csv).to be_present
      expect(oid_import).to be_valid
    end

    it "does not accept non csv files" do
      oid_import.file = File.new(Rails.root.join('public', 'favicon.ico'))
      expect(oid_import).not_to be_valid
      expect(oid_import.csv).to be_blank
    end

    it "can refresh the ParentObjects from the MetadataCloud" do
      expect(ParentObject.count).to eq 0
      oid_import.file = File.new(fixture_path + '/short_fixture_ids.csv')
      oid_import.refresh_metadata_cloud
      expect(ParentObject.count).to eq 5
    end
  end
end
