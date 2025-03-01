# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RecreateChildOidPtiffsJob, type: :job, prep_metadata_sources: true, prep_admin_sets: true do
  before do
    allow(GoodJob).to receive(:preserve_job_records).and_return(true)
    ActiveJob::Base.queue_adapter = GoodJob::Adapter.new(execution_mode: :inline)
  end

  let(:user) { FactoryBot.create(:user) }
  let(:role) { FactoryBot.create(:role, name: editor) }
  let(:admin_set) { AdminSet.first }
  let(:batch_process) { FactoryBot.create(:batch_process, user: user, batch_action: 'recreate child oid ptiffs') }
  let(:other_batch_process) { FactoryBot.create(:batch_process, user: user, batch_action: 'other recreate child oid ptiffs') }
  let(:parent_object) { FactoryBot.create(:parent_object, oid: 2_004_628, authoritative_metadata_source: MetadataSource.first, admin_set: admin_set) }
  let(:child_object) { FactoryBot.create(:child_object, oid: 456_789, parent_object: parent_object) }
  let(:recreate_child_oid_ptiffs_job) { RecreateChildOidPtiffsJob.new }
  let(:generate_ptiff_job) { GeneratePtiffJob.new }

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
    allow(batch_process).to receive(:oids).and_return(['456789'])
    child_object
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
      recreate_job = described_class.perform_later(batch_process)
      expect(recreate_job.instance_variable_get(:@successfully_enqueued)).to be true
    end
    it 'fails if the user does not have the udpate permission' do
      expect(GoodJob::Job.where(queue_name: 'ptiff').count).to eq(0)
      recreate_child_oid_ptiffs_job.perform(batch_process)
      expect(GoodJob::Job.where(queue_name: 'ptiff').count).to eq(0)
    end
    # TODO: revert back to .once instead of count: 2 once need for preservica logging is no more
    it "with recreate batch, will force ptiff creation" do
      expect(child_object.pyramidal_tiff).to receive(:original_file_exists?).and_return(true, count: 2)
      expect(child_object.pyramidal_tiff).to receive(:generate_ptiff).and_return(true, count: 2)
      generate_ptiff_job.perform(child_object, batch_process)
    end
    it "another type of batch will not force ptiff creation" do
      expect(child_object.pyramidal_tiff).not_to receive(:original_file_exists?)
      expect(child_object.pyramidal_tiff).not_to receive(:generate_ptiff)
      generate_ptiff_job.perform(child_object, other_batch_process)
    end
  end
end
