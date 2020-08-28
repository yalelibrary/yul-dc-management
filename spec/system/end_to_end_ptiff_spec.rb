# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "Creation of PTIFFs for all ChildObjects", type: :system, prep_metadata_sources: true do
  around do |example|
    perform_enqueued_jobs do
      example.run
    end
  end

  context "Child of a legacy ParentObject" do
    let(:parent_object_oid) { 2_012_036 }
    let(:child_object_oid) { 1_052_760 }
    before do
      stub_metadata_cloud("2012036")
    end

    it "make all the child_objects and all their ptiffs" do
      parent_object = ParentObject.create(oid: parent_object_oid)
      expect(parent_object.child_objects.count).to eq 5
      expect(parent_object.child_objects.first.remote_ptiff_exists?).to be true
    end
  end
end
