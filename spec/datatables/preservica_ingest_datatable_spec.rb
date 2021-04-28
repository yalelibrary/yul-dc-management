# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PreservicaIngestDatatable, type: :datatable, prep_metadata_sources: true do
  let(:user) { FactoryBot.create(:sysadmin_user) }
  columns = ['parent_oid', 'child_oid', 'preservica_id', 'batch_process_id', 'timestamp']

  it 'can handle an empty model set' do
    output = PreservicaIngestDatatable.new(datatable_sample_params(columns), current_ability: Ability.new(user)).data

    expect(output).to eq([])
  end

end
