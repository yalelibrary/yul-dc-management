# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BatchProcessDatatable, type: :datatable, prep_metadata_sources: true do
  columns = ['process_id', 'user', 'time']

  it 'can handle an empty model set' do
    output = BatchProcessDatatable.new(datatable_sample_params(columns)).data

    expect(output).to eq([])
  end

  describe 'batch process import' do
    let(:csv_upload) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "short_fixture_ids.csv")) }

    it 'can handle a csv import' do
      user = FactoryBot.create(:user, uid: 'mk2525')
      batch_process = FactoryBot.create(:batch_process, user: user, csv: csv_upload)

      output = BatchProcessDatatable.new(datatable_sample_params(columns), view_context: batch_process_datatable_view_mock(batch_process.id)).data

      expect(output.size).to eq(1)
      expect(output).to include(
        DT_RowId: batch_process.id,
        object_details: "<a href='/batch_processes/#{batch_process.id}'>View</a>",
        process_id: "<a href='/batch_processes/#{batch_process.id}'>#{batch_process.id}</a>",
        size: batch_process.oids.count,
        status: 'TODO: Status',
        time: batch_process.created_at,
        user: 'mk2525'
      )
    end
  end
end
