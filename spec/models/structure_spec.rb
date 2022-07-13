# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Structure, type: :model, prep_metadata_sources: true, prep_admin_sets: true do
  let(:oid) { "2034600" }
  let(:parent_object) { FactoryBot.create(:parent_object, oid: oid, source_name: 'ladybird', visibility: "Public") }

  before do
    stub_metadata_cloud(oid)
  end

  it 'is valid with valid attributes' do
    expect(Structure.new(parent_object_oid: parent_object.oid)).to be_valid
  end

  it 'belongs to a parent object' do
    structure = Structure.new(parent_object_oid: parent_object.oid)
    expect(structure).to belong_to(:parent_object)
  end
end
