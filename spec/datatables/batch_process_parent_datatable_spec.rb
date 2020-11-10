# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BatchProcessParentDatatable, type: :datatable, prep_metadata_sources: true do
  let(:user) { FactoryBot.create(:user, uid: 'johnsmith2530') }
  columns = ['child_oid', 'time', 'status']

  before do
    stub_metadata_cloud('16057779')
    stub_ptiffs_and_manifests
    login_as user
  end

  around do |example|
    original_image_bucket = ENV["S3_SOURCE_BUCKET_NAME"]
    ENV["S3_SOURCE_BUCKET_NAME"] = "yale-test-image-samples"
    example.run
    ENV["S3_SOURCE_BUCKET_NAME"] = original_image_bucket
  end

  describe 'batch process parent details' do
    let(:csv_upload) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, 'short_fixture_ids.csv')) }

    it 'renders a complete data table' do
      parent_object = FactoryBot.create(:parent_object, oid: 16_057_779)
      child_object = FactoryBot.create(:child_object, oid: 456_789, parent_object: parent_object)
      batch_process = FactoryBot.create(:batch_process, user: user)

      output = BatchProcessParentDatatable.new(
        batch_parent_datatable_sample_params(columns, parent_object.oid),
        view_context: batch_process_parent_datatable_view_mock(batch_process.id, parent_object.oid, child_object.oid)
      ).data

      expect(output.size).to eq(1)
      expect(output).to include(
        DT_RowId: child_object.oid,
        child_oid: "<a href='/batch_processes/#{batch_process.id}/parent_objects/#{parent_object.oid}/child_objects/#{child_object.oid}'>#{child_object.oid}</a>",
        status: 'Pending',
        time: child_object.created_at
      )
    end
  end
end
