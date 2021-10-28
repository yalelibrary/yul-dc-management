# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChildObjectDatatable, type: :datatable, prep_metadata_sources: true, prep_admin_sets: true do
  columns = ['oid', 'label', 'caption', 'width', 'height', 'order', 'parent_object', 'actions']
  let(:user) { FactoryBot.create(:sysadmin_user) }

  it 'can handle an empty model set' do
    expect(ChildObjectDatatable.new(datatable_sample_params(columns), view_context: child_object_datatable_view_mock, current_ability: Ability.new(user)).data).to eq([])
  end

  it 'renders a complete data table' do
    stub_metadata_cloud('2004628')
    admin_set = AdminSet.find_by_key('brbl')
    parent_object = FactoryBot.create(:parent_object, admin_set: admin_set)
    FactoryBot.create(:child_object, parent_object: parent_object)

    output = ChildObjectDatatable.new(datatable_sample_params(columns), view_context: child_object_datatable_view_mock, current_ability: Ability.new(user)).data

    expect(output.size).to eq(1)
    expect(output).to include(
      oid: "<a href=\"/child_objects/1\">1</a><a href=\"/management/child_objects/10736292/edit\"><i class=\"fa fa-pencil-alt\"></i></a>",
      label: nil,
      caption: 'MyString',
      width: 1,
      height: 1,
      order: 1,
      parent_object: 2_004_628,
      original_oid: nil,
      actions:
      "<a data-confirm=\"Are you sure?\" rel=\"nofollow\" data-method=\"delete\" href=\"/management/child_objects/10736292\"><i class=\"fa fa-trash\"></i></a>",
      DT_RowId: 10_736_292
    )
  end
end
