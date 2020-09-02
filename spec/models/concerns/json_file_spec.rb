# frozen_string_literal: true
require "rails_helper"

RSpec.describe JsonFile, prep_metadata_sources: true do
  let(:parent_object) { FactoryBot.create(:parent_object, oid: '16685691') }
  let(:path_to_example_file) { Rails.root.join("spec", "fixtures", "ladybird", "16685691.json") }
  around do |example|
    perform_enqueued_jobs do
      example.run
    end
  end

  before do
    allow(PyramidalTiffFactory).to receive(:generate_ptiff_from).and_return(width: 2591, height: 4056)
    stub_metadata_cloud("16685691")
  end

  it "can save a ParentObject to json" do
    time_stamp_before = File.mtime(path_to_example_file.to_s)
    parent_object.reload.to_json_file
    time_stamp_after = File.mtime(path_to_example_file.to_s)
    expect(time_stamp_before).to be < time_stamp_after
  end
end
