# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BatchProcessDatatable, type: :datatable, prep_metadata_sources: true do
  it 'can handle an empty model set' do
    output = BatchProcessDatatable.new(batch_process_datatable_sample_params).data

    expect(output).to eq([])
  end

  describe 'batch process import' do
    let(:csv_upload) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "short_fixture_ids.csv")) }

    it 'can handle a csv import' do
      user = FactoryBot.create(:user, uid: 'mk2525')
      batch_process = FactoryBot.create(:batch_process, user: user, csv: csv_upload)

      output = BatchProcessDatatable.new(batch_process_datatable_sample_params).data

      expect(output.size).to eq(1)
      expect(output).to include(
        DT_RowId: batch_process.id,
        object_details: 'View(add link)',
        process_id: batch_process.id,
        size: batch_process.oids.count,
        status: 'TODO',
        time: batch_process.created_at,
        user: 'mk2525'
      )
    end
  end
end
