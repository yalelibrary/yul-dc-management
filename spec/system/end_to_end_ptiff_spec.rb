# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "Creation of PTIFFs for all ChildObjects that are children of a given ParentObject", type: :system, prep_metadata_sources: true do
  around do |example|
    perform_enqueued_jobs do
      example.run
    end
  end

  context "legacy ParentObjects" do
    let(:oid) { 2_012_036 }
    before do
      stub_metadata_cloud("2012036")
    end

    it "makes all the child_objects and all their ptiffs" do
      parent_object = ParentObject.create(oid: oid)
      expect(parent_object.child_objects.count).to eq 5
      expect(parent_object.child_objects.first.has_ptiff?).to be true
    end
  end
end
