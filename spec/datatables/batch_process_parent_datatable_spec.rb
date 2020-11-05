# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BatchProcessParentDatatable, type: :datatable, prep_metadata_sources: true do
  columns = ['child_oid', 'time', 'status']

  describe 'batch process parent details' do
    let(:csv_upload) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, 'short_fixture_ids.csv')) }

    it 'can render the correct details' do
      user = FactoryBot.create(:user)
      parent_object = FactoryBot.create(:parent_object, oid: 16_057_779)
      child_object = FactoryBot.create(:child_object, oid: 456_789, parent_object: parent_object)
      batch_process = FactoryBot.create(:batch_process, user: user)

      output = BatchProcessParentDatatable.new(batch_parent_datatable_sample_params(columns, parent_object.oid), view_context: batch_process_parent_datatable_view_mock(batch_process.id, parent_object.oid, child_object.oid)).data

      expect(output.size).to eq(1)
      expect(output).to include(
        DT_RowId: child_object.oid,
        child_oid: "<a href='/batch_processes/#{batch_process.id}/parent_objects/#{parent_object.oid}/child_objects/#{child_object.oid}'>#{child_object.oid}</a>",
        status: 'In progress - no failures',
        time: child_object.created_at
      )
    end
  end
end
