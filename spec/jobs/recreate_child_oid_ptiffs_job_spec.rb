# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RecreateChildOidPtiffsJob, type: :job, prep_metadata_sources: true, prep_admin_sets: true do
  let(:user) { FactoryBot.create(:user) }
  let(:role) { FactoryBot.create(:role, name: editor) }
  let(:admin_set) { AdminSet.find_by(key: 'brbl') }
  let(:recreate_many) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "recreate_child_ptiffs.csv")) }
  let(:recreate_many_batch_process) { FactoryBot.create(:batch_process, user: user, file: recreate_many, batch_action: 'recreate child oid ptiffs') }
  let(:recreate_batch_process) { FactoryBot.create(:batch_process, user: user, batch_action: 'recreate child oid ptiffs') }
  let(:other_batch_process) { FactoryBot.create(:batch_process, user: user, batch_action: 'other recreate child oid ptiffs') }
  let(:parent_object) { FactoryBot.create(:parent_object, oid: 2_004_628, authoritative_metadata_source: MetadataSource.first, admin_set: admin_set) }
  let(:child_object) { FactoryBot.create(:child_object, oid: 456_789, parent_object: parent_object) }
  let(:of_many_child_object_one) { FactoryBot.create(:child_object, oid: 1_011_398, parent_object: parent_object) }
  let(:of_many_child_object_two) { FactoryBot.create(:child_object, oid: 1_126_257, parent_object: parent_object) }
  let(:of_many_child_object_three) { FactoryBot.create(:child_object, oid: 16_057_784, parent_object: parent_object) }
  let(:recreate_child_oid_ptiffs_job) { RecreateChildOidPtiffsJob.new }
  let(:generate_ptiff_job) { GeneratePtiffJob.new }

  before do
    allow(GoodJob).to receive(:preserve_job_records).and_return(true)
    ActiveJob::Base.queue_adapter = GoodJob::Adapter.new(execution_mode: :inline)
  end

  around do |example|
    original_image_bucket = ENV["S3_SOURCE_BUCKET_NAME"]
    ENV["S3_SOURCE_BUCKET_NAME"] = "not-a-real-bucket"
    example.run
    ENV["S3_SOURCE_BUCKET_NAME"] = original_image_bucket
  end

  before do
    stub_request(:head, "https://not-a-real-bucket.s3.amazonaws.com/originals/89/45/67/89/456789.tif")
        .to_return(status: 200, body: "", headers: {})
    stub_request(:head, "https://not-a-real-bucket.s3.amazonaws.com/ptiffs/89/45/67/89/456789.tif")
        .to_return(status: 200, body: "", headers: {})
    stub_request(:head, "https://not-a-real-bucket.s3.amazonaws.com/originals/98/10/11/39/1011398.tif")
        .to_return(status: 200, body: "", headers: {})
    stub_request(:head, "https://not-a-real-bucket.s3.amazonaws.com/ptiffs/98/10/11/39/1011398.tif")
        .to_return(status: 200, body: "", headers: {})
    stub_request(:head, "https://not-a-real-bucket.s3.amazonaws.com/originals/57/11/26/25/1126257.tif")
        .to_return(status: 200, body: "", headers: {})
    stub_request(:head, "https://not-a-real-bucket.s3.amazonaws.com/ptiffs/57/11/26/25/1126257.tif")
        .to_return(status: 200, body: "", headers: {})
    stub_request(:head, "https://not-a-real-bucket.s3.amazonaws.com/originals/84/16/05/77/84/16057784.tif")
        .to_return(status: 200, body: "", headers: {})
    stub_request(:head, "https://not-a-real-bucket.s3.amazonaws.com/ptiffs/84/16/05/77/84/16057784.tif")
        .to_return(status: 200, body: "", headers: {})
    allow(recreate_batch_process).to receive(:oids).and_return(['456789'])
    child_object
    of_many_child_object_one
    of_many_child_object_two
    of_many_child_object_three
  end

  describe 'recreate ptiff job' do
    it "has correct priority" do
      expect(recreate_child_oid_ptiffs_job.default_priority).to eq(9)
    end
    it "has correct queue" do
      expect(recreate_child_oid_ptiffs_job.queue_name).to eq('default')
    end
    it 'succeeds if the user has the udpate permission' do
      user.add_role(:editor, admin_set)
      expect(GoodJob::Job.where(queue_name: 'ptiff').count).to eq(0)
      recreate_job = described_class.perform_later(recreate_batch_process)
      expect(recreate_job.instance_variable_get(:@successfully_enqueued)).to be true
    end
    it 'fails if the user does not have the udpate permission' do
      expect(GoodJob::Job.where(queue_name: 'ptiff').count).to eq(0)
      recreate_child_oid_ptiffs_job.perform(recreate_batch_process)
      expect(GoodJob::Job.where(queue_name: 'ptiff').count).to eq(0)
    end
    # TODO: revert back to .once instead of count: 2 once need for preservica logging is no more
    it "with recreate batch, will force ptiff creation" do
      expect(child_object.pyramidal_tiff).to receive(:original_file_exists?).and_return(true, count: 2)
      expect(child_object.pyramidal_tiff).to receive(:generate_ptiff).and_return(true, count: 2)
      generate_ptiff_job.perform(child_object, recreate_batch_process)
    end
    it "another type of batch will not force ptiff creation" do
      expect(child_object.pyramidal_tiff).not_to receive(:original_file_exists?)
      expect(child_object.pyramidal_tiff).not_to receive(:generate_ptiff)
      generate_ptiff_job.perform(child_object, other_batch_process)
    end

    context 'when in batches' do
      around do |example|
        perform_enqueued_jobs do
          example.run
        end
      end

      before do
        stub_metadata_cloud("2002826", "ladybird")
        stub_ptiffs_and_manifests
        BatchProcess::BATCH_LIMIT = 2
        user.add_role(:editor, admin_set)
        expect(described_class).to receive(:perform_later).exactly(2).times.and_call_original
      end

      it 'can process each record once' do
        recreate_many_batch_process.save
        expect(IngestEvent.where(status: 'ptiff-queued').count).to eq 3
      end
    end
  end
end
