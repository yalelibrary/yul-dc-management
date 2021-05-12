# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PreservicaIngestDatatable, type: :datatable, prep_metadata_sources: true do
  let(:user) { FactoryBot.create(:sysadmin_user) }
  columns = ['parent_oid', 'child_oid', 'parent_preservica_id', 'parent_preservica_id', 'batch_process_id', 'timestamp']

  it 'can handle an empty model set' do
    output = described_class.new(datatable_sample_params(columns), current_ability: Ability.new(user)).data

    expect(output).to eq([])
  end

  describe 'mets xml import' do
    let(:goobi_path) { 'spec/fixtures/goobi/metadata/30000317_20201203_140947/111860A_8394689_mets.xml' }
    let(:mets_xml) { File.open(goobi_path).read }
    let(:batch_process_xml) do
      FactoryBot.create(
        :batch_process,
        user: user,
        mets_xml: mets_xml,
        file_name: 'meta.xml'
      )
    end

    it 'renders data with proper permissions' do
      batch_process_xml
      output = described_class.new(datatable_sample_params(columns), current_ability: Ability.new(user)).data

      expect(output.size).to eq(1)
      expect(output[0]).to include(
        batch_process_id: batch_process_xml.id,
        child_oid: nil,
        parent_oid: 30_000_317,
        parent_preservica_id: 'b9afab50-9f22-4505-ada6-807dd7d05733',
        child_preservica_id: nil
      )
      expect(output[0][:timestamp]).to be_within(3.seconds).of(batch_process_xml.created_at)
    end
  end
end
