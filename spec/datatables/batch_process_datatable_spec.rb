# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BatchProcessDatatable, type: :datatable, prep_metadata_sources: true do
  it 'can handle an empty model set' do
    output = BatchProcessDatatable.new(batch_process_datatable_sample_params).data

    expect(output).to eq([])
  end

  describe 'batch process import' do
    it 'can handle a csv import' do
      user = FactoryBot.create(:user, uid: "mk2525")
      batch_process = FactoryBot.create(:batch_process, user: user)
      byebug

      output = BatchProcessDatatable.new(batch_process_datatable_sample_params).data

      expect(output.size).to eq(1)
    end
  end
end
