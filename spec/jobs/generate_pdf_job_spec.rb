# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GeneratePdfJob, type: :job do
  def queue_adapter_for_test
    ActiveJob::QueueAdapters::DelayedJobAdapter.new
  end
  let(:user) { FactoryBot.create(:user) }
  let(:batch_process) { FactoryBot.create(:batch_process, user: user) }
  let(:metadata_source) { FactoryBot.create(:metadata_source) }
  let(:parent_object) { FactoryBot.create(:parent_object, oid: 2_004_628, authoritative_metadata_source: metadata_source) }
  let(:child_object) { FactoryBot.create(:child_object, oid: "456789", parent_object: parent_object) }
  let(:generate_pdf_job) { described_class.new }
  let(:parent_object_with_authoritative_json) { FactoryBot.build(:parent_object, oid: '16712419', ladybird_json: JSON.parse(File.read(File.join(fixture_path, "ladybird", "16712419.json")))) }

  around do |example|
    original_image_bucket = ENV["S3_SOURCE_BUCKET_NAME"]
    ENV["S3_SOURCE_BUCKET_NAME"] = "not-a-real-bucket"
    example.run
    ENV["S3_SOURCE_BUCKET_NAME"] = original_image_bucket
  end

  before do
    stub_request(:put, "https://not-a-real-bucket.s3.amazonaws.com/pdfs/19/16/71/24/19/16712419.pdf")
        .to_return(status: 200)
    stub_request(:head, "https://not-a-real-bucket.s3.amazonaws.com/originals/89/45/67/89/456789.tif")
        .to_return(status: 200, body: "", headers: {})
    stub_request(:head, "https://not-a-real-bucket.s3.amazonaws.com/ptiffs/89/45/67/89/456789.tif")
        .to_return(status: 200, body: "", headers: {})
    child_object
  end

  describe 'generate pdf job' do
    it 'throws exception with no authoritative_json' do
      expect do
        generate_pdf_job.perform(parent_object, batch_process)
      end.to raise_error("No authoritative_json to create PDF for #{parent_object.oid}")
    end
    it 'throws exception with shell failure' do
      expect(parent_object).to receive(:authoritative_json).and_return([]).once
      expect(parent_object).to receive(:pdf_generator_json).and_return("").once
      status = double
      expect(status).to receive(:success?).and_return(false).once
      expect(Open3).to receive(:capture3).and_return(["stdout output", "stderr output", status]).once
      expect do
        generate_pdf_job.perform(parent_object, batch_process)
      end.to raise_error("PDF Java app returned non zero response code for #{parent_object.oid}: stderr output stdout output")
    end
    it "has correct priority" do
      expect(generate_pdf_job.default_priority).to eq(50)
    end
    it "can generate a PDF file" do
      generate_pdf_job.perform(parent_object_with_authoritative_json, batch_process)
    end
  end
end
