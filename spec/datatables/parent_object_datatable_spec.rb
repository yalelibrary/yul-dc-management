# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ParentObjectDatatable, type: :datatable, prep_metadata_sources: true, prep_admin_sets: true do
  columns = ['oid', 'authoritative_source', 'bib']
  let(:user) { FactoryBot.create(:sysadmin_user) }

  it 'can handle an empty model set' do
    expect(ParentObjectDatatable.new(datatable_sample_params(columns), view_context: parent_object_datatable_view_mock, current_ability: Ability.new(user)).data).to eq([])
  end

  it 'can handle a parent object' do
    admin_set = AdminSet.find_by_key('brbl')
    oid = '2034600'

    stub_metadata_cloud(oid)
    po = FactoryBot.create(:parent_object,
                           oid: oid,
                           admin_set: admin_set,
                           extent_of_full_text: 'None',
                           mms_id: "123",
                           alma_holding: "12",
                           alma_item: "34",
                           project_identifier: '67',
                           digital_object_source: "Preservica",
                           sensitive_materials: "Yes",
                           preservica_representation_type: "Access",
                           preservica_uri: "/preservica_uri")
    output = ParentObjectDatatable.new(datatable_sample_params(columns), view_context: parent_object_datatable_view_mock, current_ability: Ability.new(user)).data

    expect(output.size).to eq(1)
    # rubocop:disable Layout/LineLength
    expect(output).to include(
      DT_RowId: 2_034_600,
      admin_set: 'brbl',
      alma_holding: "12",
      alma_item: "34",
      aspace_uri: nil,
      authoritative_source: 'ladybird',
      barcode: nil,
      bib: "752400",
      call_number: "JWJ A +Eb74",
      child_object_count: 4,
      container_grouping: nil,
      created_at: po.created_at,
      digital_object_source: "Preservica",
      digitization_funding_source: nil,
      digitization_note: nil,
      extent_of_digitization: "Partially digitized",
      full_text: 'None',
      holding: nil,
      item: nil,
      last_alma_update: nil,
      last_aspace_update: nil,
      last_id_update: nil,
      last_ladybird_update: within(1.minute).of(po.created_at),
      mms_id: "123",
      oid: '<a href="/parent_objects/2034600">2034600</a> <a href="/management/parent_objects/2034600/edit"><i class="fa fa-pencil"></i></a> <a target="_blank" href="http://localhost:3000/catalog/2034600">1</a>',
      permission_set: nil,
      preservica_uri: "/preservica_uri",
      project_identifier: nil,
      sensitive_materials: "Yes",
      visibility: 'Public'
    )
    # rubocop:enable Layout/LineLength
  end
end
