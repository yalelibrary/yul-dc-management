# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GoobiXmlImport, type: :model do
  let(:goobi_import) { described_class.new }

  it "evaluates a valid Goobi METs file as valid" do
    goobi_import.file = File.new(fixture_path + '/goobi/metadata/2012315/meta.xml')
    expect(goobi_import.goobi_xml).to be_present
    expect(goobi_import).to be_valid
  end

  it "evaluates a file missing an oid field as not valid" do
    goobi_import.file = File.new(fixture_path + '/goobi/metadata/2012315/meta_no_oid.xml')
    expect(goobi_import).not_to be_valid
  end

  it "evaluates a file with a blank oid field as not valid" do
    goobi_import.file = File.new(fixture_path + '/goobi/metadata/2012315/meta_blank_oid.xml')
    expect(goobi_import).not_to be_valid
  end
end
