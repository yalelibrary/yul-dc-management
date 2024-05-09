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
                           project_identifier: '67',
                           digital_object_source: "Preservica",
                           preservica_representation_type: "Access",
                           preservica_uri: "/preservica_uri")
    output = ParentObjectDatatable.new(datatable_sample_params(columns), view_context: parent_object_datatable_view_mock, current_ability: Ability.new(user)).data

    expect(output.size).to eq(1)
    # rubocop:disable Layout/LineLength
    expect(output).to include(
      DT_RowId: 2_034_600,
      admin_set: 'brbl',
      aspace_uri: nil,
      authoritative_source: 'ladybird',
      barcode: nil,
      bib: nil,
      child_object_count: 4,
      call_number: nil,
      container_grouping: nil,
      digital_object_source: "Preservica",
      preservica_uri: "/preservica_uri",
      digitization_note: nil,
      digitization_funding_source: nil,
      extent_of_digitization: nil,
      holding: nil,
      item: nil,
      last_aspace_update: nil,
      last_id_update: nil,
      last_ladybird_update: nil,
      last_voyager_update: nil,
      last_sierra_update: nil,
      oid: '<a href="/parent_objects/2034600">2034600</a> <a href="/management/parent_objects/2034600/edit"><i class="fa fa-pencil"></i></a> <a target="_blank" href="http://localhost:3000/catalog/2034600">1</a>',
      full_text: 'None',
      project_identifier: '67',
      permission_set: nil,
      visibility: 'Private',
      created_at: po.created_at
    )
    # rubocop:enable Layout/LineLength
  end
end
