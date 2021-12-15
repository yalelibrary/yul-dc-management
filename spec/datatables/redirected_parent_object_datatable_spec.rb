# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RedirectedParentObjectDatatable, type: :datatable, prep_metadata_sources: true, prep_admin_sets: true do
  columns = ['oid', 'authoritative_source', 'bib']
  let(:user) { FactoryBot.create(:sysadmin_user) }

  it 'can handle an empty model set' do
    expect(RedirectedParentObjectDatatable.new(datatable_sample_params(columns), view_context: redirected_parent_object_datatable_view_mock, current_ability: Ability.new(user)).data).to eq([])
  end

  it 'can handle a redirected parent object' do
    admin_set = AdminSet.find_by_key('brbl')
    oid = '2034600'
    redirect_to = "https://collections-test.library.yale.edu/catalog/1232"

    stub_metadata_cloud(oid)
    FactoryBot.create(:parent_object, oid: oid, admin_set: admin_set, redirect_to: redirect_to, visibility: 'Redirect')

    output = RedirectedParentObjectDatatable.new(datatable_sample_params(columns), view_context: redirected_parent_object_datatable_view_mock, current_ability: Ability.new(user)).data

    expect(output.size).to eq(1)
    # rubocop:disable Metrics/LineLength
    expect(output).to include(
      DT_RowId: 2_034_600,
      admin_set: 'brbl',
      authoritative_source: 'ladybird',
      oid: '<a href="/parent_objects/2034600">2034600</a> <a href="/management/parent_objects/2034600/edit"><i class="fa fa-pencil-alt"></i></a> <a target="_blank" href="http://localhost:3000/catalog/2034600">1</a>',
      redirect_to: redirect_to,
      visibility: 'Redirect'
    )
    # rubocop:enable Metrics/LineLength
  end
end
