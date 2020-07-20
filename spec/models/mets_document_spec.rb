# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MetsDocument, type: :model do
  let(:goobi_xml) { File.open(goobi_path).read }
  let(:goobi_path) { File.join(fixture_path, "goobi", "metadata", "2012315", "meta.xml") }

  it "can return the oid" do
    mets_doc = described_class.new(goobi_path)
    expect(mets_doc.oid).to eq "2012315"
  end
end
