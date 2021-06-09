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
      '2005512'
      # '2034600',
      # '14716192',
      # '16414889',
      # '16854285'
    ].each do |oid|
      stub_metadata_cloud(oid)
      FactoryBot.create(:parent_object, oid: oid, admin_set: admin_set)
    end
    first_parent_oid = ParentObject.first.oid.to_i

    output = ParentObjectDatatable.new(datatable_sample_params(columns), view_context: parent_object_datatable_view_mock(first_parent_oid), current_ability: Ability.new(user)).data

    # expect(output.size).to eq(5)
    expect(output.size).to eq(1)
    # rubocop:disable Metrics/LineLength
    expect(output).to include(
      DT_RowId: 2_005_512,
      actions: "<a data-confirm='Are you sure?' rel='nofollow' data-method='delete' href='/parent_objects/#{first_parent_oid}'><i class='fa fa-trash'></i></a><br><a data-method='post' href='/parent_objects/#{first_parent_oid}/update_metadata'>Update Metadata</a>",
      admin_set: 'brbl',
      aspace_uri: nil,
      authoritative_source: 'ladybird',
      barcode: nil,
      bib: nil,
      child_object_count: 4,
      digitization_note: nil,
      extent_of_digitization: nil,
      holding: nil,
      item: nil,
      last_aspace_update: nil,
      last_id_update: nil,
      last_ladybird_update: nil,
      last_voyager_update: nil,
      oid: "<a href='/parent_objects/#{first_parent_oid}'>#{first_parent_oid}</a> <a href='/parent_objects/#{first_parent_oid}/edit'><i class='fa fa-pencil-alt'></i></a> <a href='http://localhost:3000/catalog/#{first_parent_oid}'>#{first_parent_oid}</a>",
      visibility: "Private"
    )
    # rubocop:enable Metrics/LineLength
  end
end
