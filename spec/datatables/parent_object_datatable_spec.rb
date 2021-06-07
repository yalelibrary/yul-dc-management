# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ParentObjectDatatable, type: :datatable, prep_metadata_sources: true, prep_admin_sets: true do
  columns = ['oid', 'authoritative_source', 'bib']
  let(:user) { FactoryBot.create(:sysadmin_user) }

  it 'can handle an empty model set' do
    expect(ParentObjectDatatable.new(datatable_sample_params(columns), view_context: parent_object_datatable_view_mock, current_ability: Ability.new(user)).data).to eq([])
  end

  it 'can handle a set of parent objects' do
    admin_set = AdminSet.find_by_key('brbl')
    [
      '2034600',
      '2005512',
      '16414889',
      '14716192',
      '16854285'
    ].each do |oid|
      stub_metadata_cloud(oid)
      FactoryBot.create(:parent_object, oid: oid, admin_set: admin_set)
    end
    output = ParentObjectDatatable.new(datatable_sample_params(columns), view_context: parent_object_datatable_view_mock, current_ability: Ability.new(user)).data
    expect(output.size).to eq(5)
    expect(output).to include(
      DT_RowId: 16_854_285,
      admin_set: 'brbl',
      aspace_uri: nil,
      authoritative_source: "ladybird",
      child_object_count: 4,
      barcode: nil,
      bib: nil,
      holding: nil,
      item: nil,
      last_aspace_update: nil,
      last_id_update: nil,
      last_ladybird_update: nil,
      last_voyager_update: nil,
      oid: "<a href='/parent_objects/1'>1</a><br> <a class='btn btn-info btn-sm' href='#{ENV['BLACKLIGHT_BASE_URL'] || 'localhost:3000'}/catalog/16854285' target='_blank' > Public View</a>",
      visibility: "Private",
      extent_of_digitization: nil,
      digitization_note: nil,
      actions: '<a href="/management/parent_objects/2034601/edit">Edit</a>' \
      ' | <a data-method="post" href="/management/parent_objects/2034601/update_metadata">Update Metadata</a>' \
      ' | <a data-confirm="Are you sure?" rel="nofollow" data-method="delete" href="/management/parent_objects/2034601">Destroy</a>'
    )
  end
end
