# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GoobiXmlImport, type: :model do
  let(:goobi_import) { described_class.new }
  let(:metadata_cloud_response_body_1) { File.open(File.join(fixture_path, "ladybird", "2012315.json")).read }

  before do
    stub_request(:get, "https://metadata-api-test.library.yale.edu/metadatacloud/api/ladybird/oid/2012315")
      .to_return(status: 200, body: metadata_cloud_response_body_1)
    prep_metadata_call
  end

  it "evaluates a valid Goobi METs file as valid" do
    goobi_import.file = File.new(fixture_path + '/goobi/metadata/2012315/meta.xml')
    expect(goobi_import.goobi_xml).to be_present
    expect(goobi_import).to be_valid
  end

  it "evaluates an INvalid Goobi METs file as NOT valid" do
    goobi_import.file = File.new(fixture_path + '/goobi/metadata/2012315/meta_no_image_files.xml')
    expect(goobi_import).not_to be_valid
  end

  it "evaluates a file missing an oid field as not valid" do
    goobi_import.file = File.new(fixture_path + '/goobi/metadata/2012315/meta_no_oid.xml')
    expect(goobi_import).not_to be_valid
  end

  it "evaluates a file with a blank oid field as not valid" do
    goobi_import.file = File.new(fixture_path + '/goobi/metadata/2012315/meta_blank_oid.xml')
    expect(goobi_import).not_to be_valid
  end

  it "evaluates a goobi xml file as not valid if it can't find the associated image files" do
    goobi_import.file = File.new(fixture_path + '/goobi/metadata/2012315/meta_image_missing.xml')
    expect(goobi_import).not_to be_valid
  end

  it "can refresh the ParentObjects from the MetadataCloud" do
    expect(ParentObject.count).to eq 0
    goobi_import.file = File.new(File.join(fixture_path, "goobi", "metadata", "2012315", "meta.xml"))
    goobi_import.refresh_metadata_cloud
    expect(ParentObject.count).to eq 1
  end
end
