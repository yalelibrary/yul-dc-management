# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BatchProcessDatatable, type: :datatable, prep_metadata_sources: true do

  subject(:batch_process) { BatchProcess.new }
  let(:user) { FactoryBot.create(:user, uid: "mk2525") }
  let(:csv_upload) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "short_fixture_ids.csv")) }

  before do
    login_as(:user)
    batch_process.user_id = user.id
    stub_metadata_cloud("2034600")
    stub_metadata_cloud("2046567")
    stub_metadata_cloud("16414889")
    stub_metadata_cloud("14716192")
    stub_metadata_cloud("16854285")
    stub_metadata_cloud("16172421")
  end

  it 'can handle an empty model set' do
    expect(BatchProcessDatatable.new(batch_process_datatable_sample_params).data).to eq([])
  end


  it 'can handle a csv import' do
    output = ParentObjectDatatable.new(parent_object_datatable_sample_params, view_context: datatable_view_mock).data
    expect(output.size).to eq(1)
  end
end
