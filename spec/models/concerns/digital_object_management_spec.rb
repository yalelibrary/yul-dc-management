# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DigitalObjectManagement, type: :model, prep_metadata_sources: true, prep_admin_sets: true do
  let(:aspace) { 3 }

  it "has digital object json with expected fields" do
    full_parent_object = FactoryBot.build(:parent_object,
                                          oid: '45678',
                                          authoritative_metadata_source_id: aspace,
                                          aspace_uri: '/aspace_uri',
                                          holding: '987654321',
                                          item: '23456789',
                                          child_object_count: 1,
                                          visibility: "Private",
                                          aspace_json: { "title": ["test"] })
    full_parent_object.bib = '123456789'
    full_parent_object.barcode = '98765432'
    full_parent_object.save!
    expect(full_parent_object.digital_object_json_available?).to be_truthy
    expect(JSON.parse(full_parent_object.generate_digital_object_json)["source"]).to eq("aspace")
    expect(JSON.parse(full_parent_object.generate_digital_object_json)["bibId"]).to eq("123456789")
    expect(JSON.parse(full_parent_object.generate_digital_object_json)["holdingId"]).to eq("987654321")
    expect(JSON.parse(full_parent_object.generate_digital_object_json)["itemId"]).to eq("23456789")
    expect(JSON.parse(full_parent_object.generate_digital_object_json)["barcode"]).to eq("98765432")
  end
end
