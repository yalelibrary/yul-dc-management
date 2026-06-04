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

    FactoryBot.create(:child_object, oid: 10_736_292,
                                     parent_object: parent_object,
                                     extent_of_full_text: 'No',
                                     preservica_content_object_uri: '/content_object_uri',
                                     preservica_generation_uri: '/generation_uri',
                                     preservica_bitstream_uri: '/bitstream_uri')

    output = ChildObjectDatatable.new(datatable_sample_params(columns), view_context: child_object_datatable_view_mock, current_ability: Ability.new(user)).data

    expect(output.size).to eq(2)
    expect(output).to include(
      oid: "<a href=\"/child_objects/1\">1</a><a href=\"/management/child_objects/10736292/edit\"><i class=\"fa fa-pencil\"></i></a>",
      label: nil,
      caption: 'MyString',
      width: 1,
      height: 1,
      order: 1,
      parent_object: 2_004_628,
      original_oid: nil,
      full_text: 'No',
      preservica_content_object_uri: '/content_object_uri',
      preservica_generation_uri: '/generation_uri',
      preservica_bitstream_uri: '/bitstream_uri',
      actions:
      "<a data-confirm=\"Are you sure?\" rel=\"nofollow\" data-method=\"delete\" href=\"/management/child_objects/10736292\"><i class=\"fa fa-trash\"></i></a>",
      DT_RowId: 10_736_292
    )
  end

  describe 'record count optimizations' do
    let(:ability) { Ability.new(user) }
    let(:view_mock) { child_object_datatable_view_mock }

    before do
      stub_metadata_cloud('2004628')
      admin_set = AdminSet.find_by_key('brbl')
      @parent_object = FactoryBot.create(:parent_object, admin_set: admin_set)
      FactoryBot.create(:child_object, oid: 10_736_292, parent_object: @parent_object, caption: 'MyString')
    end

    it 'reuses the total count for the filtered count when no search is active' do
      json = ChildObjectDatatable.new(datatable_sample_params(columns), view_context: view_mock, current_ability: ability).as_json

      expect(json[:recordsTotal]).to eq(2)
      expect(json[:recordsFiltered]).to eq(json[:recordsTotal])
    end

    it 'computes a reduced filtered count when a search is active, leaving the total intact' do
      FactoryBot.create(:child_object, oid: 22_222_222, parent_object: @parent_object, caption: 'UniqueCaptionXYZ')
      searching_params = datatable_sample_params(columns)
      searching_params['search']['value'] = 'UniqueCaptionXYZ'

      json = ChildObjectDatatable.new(searching_params, view_context: view_mock, current_ability: ability).as_json

      expect(json[:recordsTotal]).to eq(3)
      expect(json[:recordsFiltered]).to eq(1)
    end

    it 'serves the total count from cache, independent of new records within the TTL window' do
      allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
      build_count = -> { ChildObjectDatatable.new(datatable_sample_params(columns), view_context: view_mock, current_ability: ability).as_json[:recordsTotal] }

      expect(build_count.call).to eq(2)
      FactoryBot.create(:child_object, oid: 33_333_333, parent_object: @parent_object)

      # A new row now exists, but the cached count is served until the entry expires.
      expect(build_count.call).to eq(2)
    end
  end
end
