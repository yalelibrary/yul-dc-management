# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReoccurringJobDatatable, type: :datatable, prep_metadata_sources: true do
  columns = ['process_id', 'run_time', 'items', 'status', 'created', 'updated', 'retrieved_records']
  let(:activity_stream) { FactoryBot.create(:activity_stream_log) }

  describe 'admin set data tables' do
    it 'can handle an empty model set' do
      output = ReoccurringJobDatatable.new(datatable_sample_params(columns)).data

      expect(output).to eq([])
    end

    it 'can handle a populated set' do
      output = ReoccurringJobDatatable.new(datatable_sample_params(columns), view_context: activity_stream_datatable_view_mock(activity_stream.id, activity_stream.run_time, activity_stream.activity_stream_items, activity_stream.status, activity_stream.created_at, activity_stream.updated_at, activity_stream.retrieved_records)).data

      expect(output).to include(

        process_id: activity_stream.id,
        run_time: activity_stream.run_time,
        items: activity_stream.activity_stream_items,
        status: activity_stream.status,
        created: activity_stream.created_at,
        updated: activity_stream.updated_at,
        retrieved_records: activity_stream.retrieved_records
      )
    end
  end
end
