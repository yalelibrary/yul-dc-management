# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DigitalObjectManagement, type: :model, prep_metadata_sources: true, prep_admin_sets: true do
  let(:aspace) { 3 }
  let(:voyager) { 2 }
  let(:admin_set) { AdminSet.first }

  it "has digital object json with expected fields" do
    full_parent_object = FactoryBot.build(:parent_object,
                                          oid: '45678',
                                          authoritative_metadata_source_id: aspace,
                                          admin_set: admin_set,
                                          aspace_uri: '/aspace_uri',
                                          holding: '987654321',
                                          item: '23456789',
                                          child_object_count: 1,
                                          visibility: "Private",
                                          aspace_json: { "title": ["test"], "volumeEnumeration": "v. 59", "callNumber": "MSS GQT" })
    full_parent_object.bib = '123456789'
    full_parent_object.barcode = '98765432'
    full_parent_object.save!
    expect(full_parent_object.digital_object_json_available?).to be_truthy
    expect(JSON.parse(full_parent_object.generate_digital_object_json)["source"]).to eq("aspace")
    expect(JSON.parse(full_parent_object.generate_digital_object_json)["bibId"]).to eq("123456789")
    expect(JSON.parse(full_parent_object.generate_digital_object_json)["holdingId"]).to eq("987654321")
    expect(JSON.parse(full_parent_object.generate_digital_object_json)["itemId"]).to eq("23456789")
    expect(JSON.parse(full_parent_object.generate_digital_object_json)["barcode"]).to eq("98765432")
    expect(JSON.parse(full_parent_object.generate_digital_object_json)["volumeEnumeration"]).to eq(nil)
    expect(JSON.parse(full_parent_object.generate_digital_object_json)["callNumber"]).to eq(nil)
  end

  describe "with VPN true and FEATURE_FLAG enabled for ILS/Voyager" do
    around do |example|
      original_vpn = ENV['VPN']
      ENV['VPN'] = "true"
      original_flags = ENV['FEATURE_FLAGS']
      ENV['FEATURE_FLAGS'] = "#{ENV['FEATURE_FLAGS']}|DO-ENABLE-ILS|" unless original_flags&.include?("|DO-ENABLE-ILS|")
      example.run
      ENV['VPN'] = original_vpn
      ENV['FEATURE_FLAGS'] = original_flags
    end

    it "can send ils digital object updates" do
      full_parent_object = FactoryBot.build(:parent_object,
                                            oid: '45678',
                                            authoritative_metadata_source_id: voyager,
                                            admin_set: admin_set,
                                            child_object_count: 1,
                                            visibility: "Private",
                                            voyager_json: { "title": ["test"], "volumeEnumeration": "v. 59", "callNumber": "MSS GQT" })
      full_parent_object.bib = '123456789'
      full_parent_object.barcode = '98765432'
      full_parent_object.holding = '987654321'
      full_parent_object.item = '23456789'
      full_parent_object.save!
      expect(full_parent_object.digital_object_json_available?).to be_truthy
      expect(JSON.parse(full_parent_object.generate_digital_object_json)["source"]).to eq("ils")
      expect(JSON.parse(full_parent_object.generate_digital_object_json)["bibId"]).to eq("123456789")
      expect(JSON.parse(full_parent_object.generate_digital_object_json)["holdingId"]).to eq("987654321")
      expect(JSON.parse(full_parent_object.generate_digital_object_json)["itemId"]).to eq("23456789")
      expect(JSON.parse(full_parent_object.generate_digital_object_json)["barcode"]).to eq("98765432")
      expect(JSON.parse(full_parent_object.generate_digital_object_json)["volumeEnumeration"]).to eq("v. 59")
      expect(JSON.parse(full_parent_object.generate_digital_object_json)["callNumber"]).to eq("MSS GQT")
    end

    it "can send aspace digital object updates with ILS enabled" do
      full_parent_object = FactoryBot.build(:parent_object,
                                            oid: '45678',
                                            authoritative_metadata_source_id: aspace,
                                            admin_set: admin_set,
                                            child_object_count: 1,
                                            visibility: "Private",
                                            aspace_json: { "title": ["test"] })
      full_parent_object.bib = '123456789'
      full_parent_object.barcode = '98765432'
      full_parent_object.holding = '987654321'
      full_parent_object.item = '23456789'
      full_parent_object.save!
      expect(full_parent_object.digital_object_json_available?).to be_truthy
      expect(JSON.parse(full_parent_object.generate_digital_object_json)["source"]).to eq("aspace")
      expect(JSON.parse(full_parent_object.generate_digital_object_json)["bibId"]).to eq("123456789")
      expect(JSON.parse(full_parent_object.generate_digital_object_json)["holdingId"]).to eq("987654321")
      expect(JSON.parse(full_parent_object.generate_digital_object_json)["itemId"]).to eq("23456789")
      expect(JSON.parse(full_parent_object.generate_digital_object_json)["barcode"]).to eq("98765432")
    end
  end
end
