# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RecreateChildOidPtiffsJob, type: :job do
  def queue_adapter_for_test
    ActiveJob::QueueAdapters::DelayedJobAdapter.new
  end
  let(:user) { FactoryBot.create(:user) }
  let(:role) { FactoryBot.create(:role, name: editor) }
  let(:admin_set) { FactoryBot.create(:admin_set) }
  let(:batch_process) { FactoryBot.create(:batch_process, user: user, batch_action: 'recreate child oid ptiffs') }
  let(:other_batch_process) { FactoryBot.create(:batch_process, user: user, batch_action: 'other recreate child oid ptiffs') }
  let(:metadata_source) { FactoryBot.create(:metadata_source) }
  let(:parent_object) { FactoryBot.create(:parent_object, oid: 2_004_628, authoritative_metadata_source: metadata_source, admin_set_id: admin_set.id) }
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
    user.add_role(:editor, admin_set)
  end

  describe 'recreate ptiff job' do
    it "has correct priority" do
      expect(recreate_child_oid_ptiffs_job.default_priority).to eq(9)
    end
    it "has correct queue" do
      expect(recreate_child_oid_ptiffs_job.queue_name).to eq('default')
    end
    it "will create appropriate number of ptiff jobs when run" do
      expect do
        recreate_child_oid_ptiffs_job.perform(batch_process)
      end.to change { Delayed::Job.where(queue: 'ptiff').count }.by(1)
    end
    it "with recreate batch, will force ptiff creation" do
      expect(child_object.pyramidal_tiff).to receive(:original_file_exists?).and_return(true).once
      expect(child_object.pyramidal_tiff).to receive(:generate_ptiff).and_return(true).once
      generate_ptiff_job.perform(child_object, batch_process)
    end
    it "another type of batch will not force ptiff creation" do
      expect(child_object.pyramidal_tiff).not_to receive(:original_file_exists?)
      expect(child_object.pyramidal_tiff).not_to receive(:generate_ptiff)
      generate_ptiff_job.perform(child_object, other_batch_process)
    end
  end
end
