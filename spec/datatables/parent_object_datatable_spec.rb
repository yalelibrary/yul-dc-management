# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ParentObjectDatatable, type: :datatable, prep_metadata_sources: true do
  it 'can handle an emapty model set' do
    expect(ParentObjectDatatable.new(datatable_sample_params).data).to eq([])
  end

  it 'can handle a set of parent objects' do
    [
      '2034600',
      '2005512',
      '16414889',
      '14716192',
      '16854285'
    ].each do |oid|
      stub_metadata_cloud(oid)
      FactoryBot.create(:parent_object, oid: oid)
    end
    output = ParentObjectDatatable.new(datatable_sample_params, view_context: datatable_view_mock).data
    expect(output.size).to eq(5)
    expect(output).to include(
      DT_RowId: 16_854_285,
      aspace_uri: nil,
      authoritative_source: "ladybird",
      barcode: nil,
      bib: nil,
      holding: nil,
      item: nil,
      last_aspace_update: nil,
      last_id_update: nil,
      last_ladybird_update: Time.zone.parse('2020-06-10 17:38:27.000000000 +0000'),
      last_voyager_update: nil,
      oid: "<a href='/parent_objects/1'>1</a><br> <a class='btn btn-info btn-sm' href='localhost:3000/catalog/16854285' target='_blank' > Discover</a>",
      visibility: "Private",
      actions: '<a href="/management/parent_objects/2034601/edit">Edit</a>' \
      ' | <a href="/management/parent_objects/2034601/update_metadata">Update Metadata</a>' \
      ' | <a data-confirm="Are you sure?" rel="nofollow" data-method="delete" href="/management/parent_objects/2034601">Destroy</a>'
    )
  end
end
