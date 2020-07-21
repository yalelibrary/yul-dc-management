# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MetsDocument, type: :model do
  let(:goobi_path) { File.join(fixture_path, "goobi", "metadata", "2012315", "meta.xml") }
  let(:valid_xml_path) { File.join(fixture_path, "goobi", "metadata", "2012315", "valid_xml.xml") }
  let(:no_image_files_path) { File.join(fixture_path, "goobi", "metadata", "2012315", "meta_no_image_files.xml") }

  it "can return the oid" do
    mets_doc = described_class.new(goobi_path)
    expect(mets_doc.oid).to eq "2012315"
  end

  describe "discerning between valid and invalid METs" do
    it "returns true for a valid mets file" do
      mets_doc = described_class.new(goobi_path)
      expect(mets_doc.valid_mets?).to be_truthy
    end

    it "returns false for a valid xml file that is not METs" do
      mets_doc = described_class.new(valid_xml_path)
      expect(mets_doc.valid_mets?).to be_falsey
    end

    it "returns false for a valid METs file that does not point to any images" do
      mets_doc = described_class.new(no_image_files_path)
      expect(mets_doc.valid_mets?).to be_falsey
    end
  end
end
