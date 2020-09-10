# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OidImport, type: :model, prep_metadata_sources: true do
  subject(:oid_import) { described_class.new }

  before do
    stub_metadata_cloud("2034600")
    stub_metadata_cloud("2046567")
    stub_metadata_cloud("16414889")
    stub_metadata_cloud("14716192")
    stub_metadata_cloud("16854285")
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

    it "can identify the metadata source" do
      oid_import.file = File.new(fixture_path + '/short_fixture_ids_with_source.csv')
      oid_import.refresh_metadata_cloud
      byebug
      expect(ParentObject.first.authoritative_metadata_source_id).to eq 1
      expect(ParentObject.second.authoritative_metadata_source_id).to eq 2
      expect(ParentObject.third.authoritative_metadata_source_id).to eq 3
    end

  end
end
