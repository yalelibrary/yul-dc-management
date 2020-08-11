# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MetsXmlImport, type: :model, prep_metadata_sources: true do
  let(:mets_import) { described_class.new }

  before do
    stub_metadata_cloud("2012315")
  end

  it "has an oid associated with it" do
    mets_import.file = File.new(fixture_path + '/goobi/metadata/2012315/meta.xml')
    expect(mets_import.oid).to eq "2012315"
  end

  it "has a mets document associated with it that is not saved to the database" do
    mets_import.file = File.new(fixture_path + '/goobi/metadata/2012315/meta.xml')
    expect(mets_import.mets_doc.valid_mets?).to eq true
  end

  it "evaluates a valid Goobi METs file as valid" do
    mets_import.file = File.new(fixture_path + '/goobi/metadata/2012315/meta.xml')
    expect(mets_import.mets_xml).to be_present
    expect(mets_import).to be_valid
  end

  it "evaluates an INvalid Goobi METs file as NOT valid" do
    mets_import.file = File.new(fixture_path + '/goobi/metadata/2012315/meta_no_image_files.xml')
    expect(mets_import).not_to be_valid
  end

  it "evaluates a file missing an oid field as not valid" do
    mets_import.file = File.new(fixture_path + '/goobi/metadata/2012315/meta_no_oid.xml')
    expect(mets_import).not_to be_valid
  end

  it "evaluates a file with a blank oid field as not valid" do
    mets_import.file = File.new(fixture_path + '/goobi/metadata/2012315/meta_blank_oid.xml')
    expect(mets_import).not_to be_valid
  end

  it "evaluates a goobi xml file as not valid if it can't find the associated image files" do
    mets_import.file = File.new(fixture_path + '/goobi/metadata/2012315/meta_image_missing.xml')
    expect(mets_import).not_to be_valid
  end

  it "can refresh the ParentObjects from the MetadataCloud" do
    expect(ParentObject.count).to eq 0
    mets_import.file = File.new(File.join(fixture_path, "goobi", "metadata", "2012315", "meta.xml"))
    mets_import.refresh_metadata_cloud
    expect(ParentObject.count).to eq 1
  end

  context "with a valid mets xml without a Goobi namespace" do
    it "does not error out" do
      mets_import.file = File.new(fixture_path + '/goobi/no_goobi_namespace.xml')
      expect(mets_import).not_to be_valid
    end
  end
end
