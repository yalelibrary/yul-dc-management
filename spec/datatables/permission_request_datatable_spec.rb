# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PermissionRequestDatatable, type: :datatable, prep_metadata_sources: true, prep_admin_sets: true do
  columns = ['id', 'permission_set', 'request_date', 'oid', 'user_name', 'sub', 'net_id', 'request_status', 'approver']
  let(:user) { FactoryBot.create(:sysadmin_user) }

  it 'can handle an empty model set' do
    expect(PermissionRequestDatatable.new(datatable_sample_params(columns), current_ability: Ability.new(user)).data).to eq([])
  end

  it 'can handle a permission request' do
    pr = FactoryBot.create(:permission_request)
    output = PermissionRequestDatatable.new(datatable_sample_params(columns), view_context: pr_datatable_view_mock(pr.id, pr.permission_set.id), current_ability: Ability.new(user)).data

    expect(output.size).to eq(1)
    expect(output).to include(
      DT_RowId: pr.id,
      id: "<a href='/permission_requests/#{pr.id}'>#{pr.id}</a> <a href='/permission_requests/#{pr.id}'>#{pr.id}</a>",
      permission_set: "<a href='/permission_sets/#{pr.permission_set.id}'>#{pr.permission_set.label}</a>",
      request_date: pr.created_at,
      oid: pr.parent_object.oid,
      user_name: pr.permission_request_user.name,
      sub: pr.permission_request_user.sub,
      net_id: pr.permission_request_user.netid,
      request_status: pr.request_status,
      approver: 'TODO'
    )
  end

  it 'can render permission requests that user is administrator or approver of permission set' do
    reg_user = FactoryBot.create(:user)
    as = AdminSet.first
    ps_one = FactoryBot.create(:permission_set, key: 'abc', label: 'handsome')
    ps_two = FactoryBot.create(:permission_set, key: 'def', label: 'dan')
    po_one = FactoryBot.create(:parent_object, permission_set: ps_one, oid: '3456789')
    po_two = FactoryBot.create(:parent_object, permission_set: ps_two, oid: '1234567')
    pr_one = FactoryBot.create(:permission_request, permission_set: ps_one, parent_object: po_one)
    pr_two = FactoryBot.create(:permission_request, permission_set: ps_two, parent_object: po_two)

    as.add_editor(reg_user)
    ps_one.add_administrator(reg_user)

    output = PermissionRequestDatatable.new(datatable_sample_params(columns), view_context: pr_datatable_view_mock(pr_one.id, ps_one.id), current_ability: Ability.new(reg_user)).data

    expect(output.size).to eq(1)
    expect(output).to include(
      DT_RowId: pr_one.id,
      approver: "TODO",
      id: "<a href='/permission_requests/#{pr_one.id}'>#{pr_one.id}</a> <a href='/permission_requests/#{pr_one.id}'>#{pr_one.id}</a>",
      net_id: pr_one.permission_request_user.netid,
      oid: pr_one.parent_object.oid,
      permission_set: "<a href='/permission_sets/#{pr_one.permission_set.id}'>#{pr_one.permission_set.label}</a>",
      request_date: pr_one.created_at,
      request_status: pr_one.request_status,
      sub: pr_one.permission_request_user.sub,
      user_name: pr_one.permission_request_user.name
    )
    expect(output).not_to include(pr_two.permission_set.label)
  end
end
