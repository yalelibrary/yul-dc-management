# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChildObjectDatatable, type: :datatable, prep_metadata_sources: true, prep_admin_sets: true do
  columns = ['oid', 'label', 'caption', 'width', 'height', 'order', 'parent_object', 'actions']
  let(:user) { FactoryBot.create(:sysadmin_user) }

  it 'can handle an empty model set' do
    expect(ChildObjectDatatable.new(datatable_sample_params(columns), view_context: child_object_datatable_view_mock, current_ability: Ability.new(user)).data).to eq([])
  end

end
