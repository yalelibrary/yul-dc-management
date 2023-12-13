# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GeneratePdfJob, type: :job, prep_metadata_sources: true, prep_admin_sets: true do
  before do
    allow(GoodJob).to receive(:preserve_job_records).and_return(true)
    ActiveJob::Base.queue_adapter = GoodJob::Adapter.new(execution_mode: :inline)
  end

  let(:user) { FactoryBot.create(:user) }
  let(:batch_process) { FactoryBot.create(:batch_process, user: user) }
  let(:parent_object) { FactoryBot.create(:parent_object, oid: 2_004_628, authoritative_metadata_source: MetadataSource.first, admin_set: AdminSet.first) }
  let(:child_object) { FactoryBot.create(:child_object, oid: "456789", parent_object: parent_object) }
  let(:generate_pdf_job) { GeneratePdfJob.new }
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
        generate_pdf_job.perform(parent_object)
      end.to raise_error("No authoritative_json to create PDF for #{parent_object.oid}")
    end
    it 'throws exception with shell failure' do
      allow(S3Service).to receive(:remote_metadata).and_return(parent_object)
      # stub these with some values so that it will get to the point of trying to run the app and get the response
      # from Open3.capture3 with success = false  (the values don't really matter)
      expect(parent_object).to receive(:authoritative_json).and_return(true).once
      expect(parent_object).to receive(:pdf_json_checksum).and_return("some_generic_checksum").once
      expect(parent_object).to receive(:pdf_generator_json).and_return('{}').once
      status = double
      expect(status).to receive(:success?).and_return(false)
      expect(Open3).to receive(:capture3).and_return(["stdout output", "stderr output", status])
      expect do
        generate_pdf_job.perform(parent_object)
      end.to raise_error("PDF Java app returned non zero response code for #{parent_object.oid}: stderr output stdout output")
    end
    it "has correct priority" do
      expect(generate_pdf_job.default_priority).to eq(50)
    end
    it "can generate a PDF file" do
      allow(S3Service).to receive(:remote_metadata).and_return(parent_object_with_authoritative_json)
      generate_pdf_job.perform(parent_object_with_authoritative_json)
    end

    context "when pdf metadata is present with matching checksum" do
      before do
        stub_request(:head, "https://not-a-real-bucket.s3.amazonaws.com/pdfs/19/16/71/24/19/16712419.pdf")
            .to_return(status: 200, headers: { "x-amz-meta-pdfchecksum": parent_object_with_authoritative_json.pdf_json_checksum })
      end
      it "generate_pdf returns false because it does not generate pdf" do
        expect(parent_object_with_authoritative_json.generate_pdf).to be_falsey
      end
    end

    it "will not generate the same pdf twice" do
    end
  end
end
