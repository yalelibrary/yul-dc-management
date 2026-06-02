# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DigitalObjectManagement, type: :model, prep_metadata_sources: true, prep_admin_sets: true do
  let(:aspace) { 3 }
  let(:voyager) { 2 }
  let(:alma) { 5 }

  describe "with VPN true and FEATURE_FLAG enabled for ILS/Voyager" do
    around do |example|
      original_vpn = ENV['VPN']
      ENV['VPN'] = "true"
      original_flags = ENV['FEATURE_FLAGS']
      ENV['FEATURE_FLAGS'] = "#{ENV['FEATURE_FLAGS']}|DO-ENABLE-ILS|" unless original_flags&.include?("|DO-ENABLE-ILS|")
      ENV['FEATURE_FLAGS'] = "#{ENV['FEATURE_FLAGS']}|DO-ENABLE-ALMA|" unless original_flags&.include?("|DO-ENABLE-ALMA|")
      example.run
      ENV['VPN'] = original_vpn
      ENV['FEATURE_FLAGS'] = original_flags
    end

    context "generating digital object JSON" do
      before do
        allow(S3Service).to receive(:download).and_return(File.read(fixture_paths[0] + "/aspace/AS-781086.json"))
        allow(S3Service).to receive(:download).and_return(File.read(fixture_paths[0] + "/alma/A-15821166.json"))
      end

      it "has digital object json with expected fields" do
        allow_any_instance_of(MetadataSource).to receive(:fetch_record).and_return(File.read(fixture_paths[0] + "/aspace/AS-781086.json"))
        full_parent_object = FactoryBot.create(:parent_object,
                                              oid: '781086',
                                              authoritative_metadata_source_id: aspace,
                                              aspace_uri: '/aspace_uri',
                                              holding: '987654321',
                                              item: '23456789',
                                              child_object_count: 1,
                                              visibility: "Private",
                                              sensitive_materials: "Yes",
                                              aspace_json: File.read(fixture_paths[0] + "/aspace/AS-781086.json"))
        full_parent_object.bib = '123456789'
        full_parent_object.barcode = '98765432'
        full_parent_object.save!
        expect(full_parent_object.digital_object_json_available?).to be_truthy
        expect(JSON.parse(full_parent_object.generate_digital_object_json)["source"]).to eq("aspace")
        expect(JSON.parse(full_parent_object.generate_digital_object_json)["bibId"]).to eq("123456789")
        expect(JSON.parse(full_parent_object.generate_digital_object_json)["holdingId"]).to eq("987654321")
        expect(JSON.parse(full_parent_object.generate_digital_object_json)["itemId"]).to eq("23456789")
        expect(JSON.parse(full_parent_object.generate_digital_object_json)["barcode"]).to eq("98765432")
        expect(JSON.parse(full_parent_object.generate_digital_object_json)["sensitiveMaterials"]).to eq("Yes")
        expect(JSON.parse(full_parent_object.generate_digital_object_json)["volumeEnumeration"]).to eq(nil)
        expect(JSON.parse(full_parent_object.generate_digital_object_json)["callNumber"]).to eq(nil)
      end

      it "can send alma digital object updates" do
        allow_any_instance_of(MetadataSource).to receive(:fetch_record).and_return(File.read(fixture_paths[0] + "/alma/A-15821166.json"))
        allow_any_instance_of(ParentObject).to receive(:authoritative_json).and_return(JSON.parse(File.read(fixture_paths[0] + "/alma/A-15821166.json")))
        full_parent_object = FactoryBot.create(:parent_object,
                                              oid: '15821166',
                                              authoritative_metadata_source_id: alma,
                                              alma_item: '23456789',
                                              child_object_count: 1,
                                              visibility: "Private",
                                              alma_json: File.read(fixture_paths[0] + "/alma/A-15821166.json"))
        full_parent_object.mms_id = '123456789'
        full_parent_object.barcode = '98765432'
        full_parent_object.alma_holding = '987654321'
        full_parent_object.alma_item = '23456789'
        full_parent_object.save!
        expect(full_parent_object.digital_object_json_available?).to be_truthy
        expect(JSON.parse(full_parent_object.generate_digital_object_json)["source"]).to eq("alma")
        expect(JSON.parse(full_parent_object.generate_digital_object_json)["bibId"]).to eq("123456789")
        expect(JSON.parse(full_parent_object.generate_digital_object_json)["holdingId"]).to eq("987654321")
        expect(JSON.parse(full_parent_object.generate_digital_object_json)["itemId"]).to eq("23456789")
        expect(JSON.parse(full_parent_object.generate_digital_object_json)["barcode"]).to eq("98765432")
        expect(JSON.parse(full_parent_object.generate_digital_object_json)["volumeEnumeration"]).to eq("v. 59")
        expect(JSON.parse(full_parent_object.generate_digital_object_json)["callNumber"]).to eq("96 1667")
      end

      it "can send aspace digital object updates with ILS enabled" do
        allow_any_instance_of(MetadataSource).to receive(:fetch_record).and_return(File.read(fixture_paths[0] + "/aspace/AS-781086.json"))
        full_parent_object = FactoryBot.create(:parent_object,
                                              oid: '781086',
                                              authoritative_metadata_source_id: aspace,
                                              child_object_count: 1,
                                              visibility: "Private",
                                              aspace_json: File.read(fixture_paths[0] + "/aspace/AS-781086.json"))
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
end
