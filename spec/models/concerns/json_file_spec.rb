# frozen_string_literal: true
require "rails_helper"

RSpec.describe JsonFile do
  let(:parent_object) { FactoryBot.create(:parent_object) }
  let(:path_to_example_file) { Rails.root.join("spec", "fixtures", "ladybird", "2004628.json") }
  before do
    prep_metadata_call
    stub_request(:get, "https://metadata-api-test.library.yale.edu/metadatacloud/api/ladybird/oid/2004628")
      .to_return(status: 200, body: File.open(File.join(fixture_path, "ladybird", "2004628.json")).read)
  end

  it "can save a ParentObject to json" do
    time_stamp_before = File.mtime(path_to_example_file.to_s)
    parent_object.to_json_file
    time_stamp_after = File.mtime(path_to_example_file.to_s)
    expect(time_stamp_before).to be < time_stamp_after
  end
end
