# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MetsXmlImport, type: :model, prep_metadata_sources: true do
  let(:mets_import) { described_class.new }

  around do |example|
    original_path = ENV["GOOBI_MOUNT"]
    ENV["GOOBI_MOUNT"] = File.join("spec", "fixtures", "goobi", "metadata")
    example.run
    ENV["GOOBI_MOUNT"] = original_path
  end

  before do
    stub_metadata_cloud("16172421")
  end

  it "does not error out" do
    mets_import.file = File.new(fixture_path + '/goobi/metadata/16172421/meta.xml')
    expect(mets_import).to be_valid
  end

  it "has an oid associated with it" do
    mets_import.file = File.new(fixture_path + '/goobi/metadata/16172421/meta.xml')
    expect(mets_import.oid).to eq 16_172_421
  end

  it "has a mets document associated with it that is not saved to the database" do
    mets_import.file = File.new(fixture_path + '/goobi/metadata/16172421/meta.xml')
    expect(mets_import.mets_doc.valid_mets?).to eq true
  end

  it "evaluates a valid METs file as valid" do
    mets_import.file = File.new(fixture_path + '/goobi/metadata/16172421/meta.xml')
    expect(mets_import.mets_xml).to be_present
    expect(mets_import).to be_valid
  end

  it "can refresh the ParentObjects from the MetadataCloud" do
    expect(ParentObject.count).to eq 0
    mets_import.file = File.new(File.join(fixture_path, "goobi", "metadata", "16172421", "meta.xml"))
    mets_import.refresh_metadata_cloud
    expect(ParentObject.count).to eq 1
  end
end
