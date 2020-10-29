# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BatchProcessDetailDatatable, type: :datatable, prep_metadata_sources: true do
  columns = ['parent_oid', 'time', 'children']

  describe 'batch process import' do
    let(:csv_upload) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "short_fixture_ids.csv")) }

    it 'can handle a csv import' do
      user = FactoryBot.create(:user, uid: 'mk2525')
      batch_process = FactoryBot.create(:batch_process, user: user, csv: csv_upload, oid: "2034600")

      parent_object = FactoryBot.create(:parent_object, oid: batch_process.oid)

      output = BatchProcessDetailDatatable.new(datatable_sample_params(columns, batch_process.id)).data

  #     output = BatchProcessDetailDatatable.new(datatable_sample_params(columns), view_context: batch_process_datatable_view_mock(batch_process.id)).data

  #     expect(output.size).to eq(1)
  #     expect(output).to include(
  #       DT_RowId: batch_process.id,
  #       object_details: "<a href='/batch_processes/#{batch_process.id}'>View</a>",
  #       process_id: "<a href='/batch_processes/#{batch_process.id}'>#{batch_process.id}</a>",
  #       size: batch_process.oids.count,
  #       status: 'TODO: Status',
  #       time: batch_process.created_at,
  #       user: 'mk2525'
  #     )
  #   end
  # end
end
