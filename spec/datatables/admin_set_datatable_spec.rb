# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdminSetDatatable, type: :datatable, prep_metadata_sources: true do
  columns = ['key', 'label', 'homepage']
  let(:admin_set) { FactoryBot.create(:admin_set) }

  describe 'admin set data tables' do
    it 'can handle an empty model set' do
      output = AdminSetDatatable.new(datatable_sample_params(columns)).data

      expect(output).to eq([])
    end

    it 'can handle a populated set' do
      output = AdminSetDatatable.new(datatable_sample_params(columns), view_context: admin_set_datatable_view_mock(admin_set.id, admin_set.key, admin_set.homepage)).data

      expect(output).to include(
        DT_RowId: "admin_set_#{admin_set.id}",
        homepage: "<a href=#{admin_set.homepage}>#{admin_set.homepage}</a>",
        key: "<a href='/admin_sets/#{admin_set.id}'>#{admin_set.key}</a><a href='/admin_sets/#{admin_set.id}/edit'><i class=\"fa fa-pencil-alt></i>\"</a>",
        label: admin_set.key.to_s
      )
    end
  end
end
