# frozen_string_literal: true
require 'rails_helper'

RSpec.describe CreateChildOidCsvJob, type: :job do
  before do
    allow(GoodJob).to receive(:preserve_job_records).and_return(true)
    ActiveJob::Base.queue_adapter = GoodJob::Adapter.new(execution_mode: :external)
  end

  let(:user) { FactoryBot.create(:user) }
  let(:batch_process) { FactoryBot.create(:batch_process, user: user) }
  let(:create_child_oid_csv_job) { CreateChildOidCsvJob.new }
  let(:expected_child_headers) do
    ['parent_oid', 'child_oid', 'order', 'parent_title', 'call_number', 'label', 'caption', 'viewing_hint', 'full_text',
     'x_resolution', 'y_resolution', 'resolution_unit', 'color_space', 'compression', 'iptc_creator', 'date_and_time_captured', 'make', 'model']
  end

  it 'increments the job queue by one' do
    create_child_oid_csv_job = described_class.perform_later(batch_process)
    expect(create_child_oid_csv_job.instance_variable_get(:@successfully_enqueued)).to be true
  end

  it "has correct priority" do
    expect(create_child_oid_csv_job.default_priority).to eq(-100)
  end

  it "has correct queue" do
    expect(create_child_oid_csv_job.queue_name).to eq('default')
  end

  it 'calls child_output_csv when performed' do
    expect(batch_process).to receive(:child_output_csv).once
    described_class.new.perform(batch_process)
  end

  context 'when child_output_csv raises an exception' do
    let(:error_message) { 'Something went wrong' }
    let(:error) { StandardError.new(error_message) }

    before do
      allow(batch_process).to receive(:child_output_csv).and_raise(error)
      allow(batch_process).to receive(:batch_processing_event)
    end

    it 'logs the error with batch_processing_event' do
      expect(batch_process).to receive(:batch_processing_event)
        .with("Setup job failed to save: #{error_message}", "failed")

      expect do
        described_class.new.perform(batch_process)
      end.not_to raise_error
    end
  end

  context 'when exporting child oids', prep_metadata_sources: true, prep_admin_sets: true do
    let(:batch_process) { FactoryBot.create(:batch_process, user: user, batch_action: 'export child oids') }
    let(:parent_object) { FactoryBot.create(:parent_object, oid: '2002826', admin_set: AdminSet.first) }
    let!(:child_object) { FactoryBot.create(:child_object, oid: '456789', parent_object: parent_object) }

    it 'includes child_headers in the CSV output' do
      described_class.new.perform(batch_process)
      output_csv = batch_process.child_output_csv
      csv_rows = CSV.parse(output_csv)
      header_row = csv_rows.first

      expect(header_row).to eq(expected_child_headers)
    end
  end
end
