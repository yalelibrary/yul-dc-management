# frozen_string_literal: true
require "rails_helper"

RSpec.describe JsonFile, prep_metadata_sources: true do
  let(:parent_object) { FactoryBot.create(:parent_object, oid: '100001') }
  let(:path_to_example_file) { Rails.root.join("spec", "fixtures", "ladybird", "100001.json") }
  before do
    stub_request(:get, "https://yul-development-samples.s3.amazonaws.com/ladybird/100001.json")
      .to_return(status: 200, body: File.open(File.join(fixture_path, "ladybird", "100001.json")).read)
  end

  it "can save a ParentObject to json" do
    time_stamp_before = File.mtime(path_to_example_file.to_s)
    parent_object.to_json_file
    time_stamp_after = File.mtime(path_to_example_file.to_s)
    expect(time_stamp_before).to be < time_stamp_after
  end
end
