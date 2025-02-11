# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReassociateChildOidsJob, type: :job, prep_admin_sets: true, prep_metadata_sources: true do
  let(:admin_set) { AdminSet.find_by(key: 'brbl') }
  let(:user) { FactoryBot.create(:user) }
  let(:create_many) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "create_many_parent_fixture_ids.csv")) }
  let(:reassociate_many) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "reassociate_many_child_objects.csv")) }
  let(:create_batch_process) { FactoryBot.create(:batch_process, user: user, file: create_many) }
  let(:reassociate_batch_process) { FactoryBot.create(:batch_process, user: user, file: reassociate_many, batch_action: 'reassociate child oids') }
  let(:parent_object_old_two) { FactoryBot.create(:parent_object, oid: 2_002_826) }

  before do
    allow(GoodJob).to receive(:preserve_job_records).and_return(true)
    ActiveJob::Base.queue_adapter = GoodJob::Adapter.new(execution_mode: :inline)
  end

  let(:metadata_job) { ReassociateChildOidsJob.new }

  it 'increments the job queue by one' do
    reassociate_child_oids_job = described_class.perform_later(metadata_job)
    expect(reassociate_child_oids_job.instance_variable_get(:@successfully_enqueued)).to be true
  end

  context 'job fails' do
    let(:user) { FactoryBot.create(:user) }
    let(:batch_process) { FactoryBot.create(:batch_process, batch_action: 'reassociate child oids', user: user) }
    let(:metadata_source) { MetadataSource.first }

    it 'notifies on save failure' do
      allow(batch_process).to receive(:reassociate_child_oids).and_raise('boom!')
      expect { metadata_job.perform(batch_process) }.to change { IngestEvent.count }.by(1)
      expect(IngestEvent.last.reason).to eq "ReassociateChildOidsJob failed due to boom!"
      expect(IngestEvent.last.status).to eq "failed"
    end
  end

  context 'with more than limit of batch objects' do
    before do
      BatchProcess::BATCH_LIMIT = 2
      expect(ParentObject.all.count).to eq 0
      stub_metadata_cloud("2005512", "ladybird")
      stub_metadata_cloud("2002826", "ladybird")
      stub_ptiffs_and_manifests
      user.add_role(:editor, admin_set)
      login_as(:user)
      create_batch_process.save
      parent_object_old_two
      total_parent_object_count = 5
      total_child_object_count = 3
      expect(ParentObject.all.count).to eq total_parent_object_count
      expect(ChildObject.all.count).to eq total_child_object_count
      po_one = ParentObject.find(2_005_512)
      po_five = ParentObject.find(2_002_826)
      expect(po_one.child_object_count).to eq 2
      expect(po_five.child_object_count).to eq 1
      expect(described_class).to receive(:perform_later).exactly(2).times.and_call_original
    end

    around do |example|
      perform_enqueued_jobs do
        original_image_bucket = ENV['ACCESS_MASTER_MOUNT']
        ENV['ACCESS_MASTER_MOUNT'] = File.join('spec', 'fixtures', 'images', 'ptiff_images')
        example.run
        ENV['ACCESS_MASTER_MOUNT'] = original_image_bucket
      end
    end

    it 'goes through all parents in batches once' do
      reassociate_batch_process.save
      po_one = ParentObject.find(2_005_512)
      po_two = ParentObject.find(2_005_513)
      po_three = ParentObject.find(2_005_514)
      po_four = ParentObject.find(2_005_515)
      po_five = ParentObject.find(2_002_826)
      co_one = ChildObject.find(1_030_368)
      co_two = ChildObject.find(1_032_318)
      co_three = ChildObject.find(1_011_398)
      # four rows in csv
      expect(IngestEvent.where(status: 'update-complete').count).to eq 4
      # parent create and four parent updates
      expect(IngestEvent.where(status: 'manifest-saved').count).to eq 5
      expect(po_one.child_object_count).to eq(0).or be_nil
      expect(po_two.child_object_count).to eq(0).or be_nil
      expect(po_three.child_object_count).to eq(0).or be_nil
      expect(po_four.child_object_count).to eq(0).or be_nil
      expect(po_five.child_object_count).to eq 3
      expect(co_one.parent_object_oid).to eq po_five.oid
      expect(co_two.parent_object_oid).to eq po_five.oid
      expect(co_three.parent_object_oid).to eq po_five.oid
    end
  end
end
