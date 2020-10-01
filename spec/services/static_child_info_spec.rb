# frozen_string_literal: true
require "rails_helper"

RSpec.describe StaticChildInfo, prep_metadata_sources: true do
  let(:parent_object) { FactoryBot.create(:parent_object, oid: 2_004_628) }
  let(:child_object) { FactoryBot.create(:child_object, oid: 111, parent_object: parent_object) }
  let(:child_object_no_size) { FactoryBot.create(:child_object, oid: 222, parent_object: parent_object, width: nil, height: nil) }

  it "writes json for each child object with width and height" do
    expect(child_object).to be
    expect(child_object_no_size).to be
    expect(JSON).to receive(:pretty_generate).with(111 => { width: 1, height: 1 }).and_return('JSON')
    expect(File).to receive(:write).and_return true
    expect(StaticChildInfo.write_sizes).to be_truthy
  end
end
