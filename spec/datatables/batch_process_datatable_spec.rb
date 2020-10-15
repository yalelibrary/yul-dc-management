# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BatchProcessDatatable, type: :datatable, prep_metadata_sources: true do
  it 'can handle an empty model set' do
    expect(BatchProcessDatatable.new(batch_process_datatable_sample_params).data).to eq([])
  end
end
