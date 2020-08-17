# frozen_string_literal: true
require "rails_helper"

RSpec.describe JsonFile, prep_metadata_sources: true do
  let(:parent_object) { FactoryBot.create(:parent_object, oid: '2003431') }
  let(:path_to_example_file) { Rails.root.join("spec", "fixtures", "ladybird", "2003431.json") }
  before do
    stub_metadata_cloud("2003431")
  end

  it "can save a ParentObject to json" do
    time_stamp_before = File.mtime(path_to_example_file.to_s)
    parent_object.to_json_file
    time_stamp_after = File.mtime(path_to_example_file.to_s)
    expect(time_stamp_before).to be < time_stamp_after
  end
end
