# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChildObject, type: :model, prep_metadata_sources: true do
  let(:parent_object) { FactoryBot.create(:parent_object, oid: 2_004_628) }
  let(:child_object) { described_class.create(oid: "456789", parent_object: parent_object) }

  before do
    stub_metadata_cloud("2004628")
    parent_object
  end

  it "can access the parent object" do
    expect(child_object.parent_object).to be_instance_of ParentObject
  end
end
