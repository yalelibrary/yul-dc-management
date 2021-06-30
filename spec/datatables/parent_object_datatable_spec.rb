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
    FactoryBot.create(:parent_object, oid: oid, admin_set: admin_set)

    output = ParentObjectDatatable.new(datatable_sample_params(columns), view_context: parent_object_datatable_view_mock, current_ability: Ability.new(user)).data

    expect(output.size).to eq(1)
    # rubocop:disable Metrics/LineLength
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
      digitization_note: nil,
      extent_of_digitization: nil,
      holding: nil,
      item: nil,
      last_aspace_update: nil,
      last_id_update: nil,
      last_ladybird_update: nil,
      last_voyager_update: nil,
      oid: '<a href="/parent_objects/2034600">2034600</a> <a href="/management/parent_objects/2034600/edit"><i class="fa fa-pencil-alt"></i></a> <a href="http://localhost:3000/catalog/2034600">1</a>',
      visibility: 'Private'
    )
    # rubocop:enable Metrics/LineLength
  end
end
