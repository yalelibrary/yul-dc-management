# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DeleteParentObjectsJob, type: :job, prep_metadata_sources: true, prep_admin_sets: true do
  let(:admin_set) { AdminSet.find_by(key: 'brbl') }
  let(:user) { FactoryBot.create(:user) }
  let(:create_many) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "create_many_parent_fixture_ids.csv")) }
  let(:delete_many) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "delete_many_parent_fixture_ids.csv")) }
  let(:create_batch_process) { FactoryBot.create(:batch_process, user: user, file: create_many) }
  let(:delete_batch_process) { FactoryBot.create(:batch_process, user: user, file: delete_many, batch_action: 'delete parent objects') }

  before do
    allow(GoodJob).to receive(:preserve_job_records).and_return(true)
    ActiveJob::Base.queue_adapter = GoodJob::Adapter.new(execution_mode: :inline)
  end
  
  context 'with tests active job queue' do

    it 'increments the job queue by one' do
      delete_parent_job = described_class.perform_later
      expect(delete_parent_job.instance_variable_get(:@successfully_enqueued)).to be true
    end
  end

  context 'with more than limit parent objects' do

    before do
      Deletable::BATCH_LIMIT = 2
      expect(ParentObject.all.count).to eq 0
      user.add_role(:editor, admin_set)
      login_as(:user)
      create_batch_process.save
      total_parent_object_count = 4
      expect(ParentObject.all.count).to eq total_parent_object_count
      # delete_batch_process.save

      delete_this_batch_process = double




      expect(delete_this_batch_process).to receive(:delete_parent_objects).with(0).exactly(1).times
    end

    context 'with jobs enqueued around' do

      around do |example|
        perform_enqueued_jobs do
          example.run
        end
      end

      it 'goes through all parents in batches once' do
        DeleteParentObjectsJob.perform_now(delete_batch_process)
        expect(IngestEvent.where(status: 'deleted').and(IngestEvent.where(reason: 'Parent 2005512 has been deleted')).count).to eq 1
        expect(IngestEvent.where(status: 'Skipped Row').and(IngestEvent.where(reason: 'Skipping row [2] with parent oid: 2005512 because it was not found in local database')).count).to eq 0
        expect(IngestEvent.where(status: 'deleted').and(IngestEvent.where(reason: 'Parent 2005513 has been deleted')).count).to eq 1
        expect(IngestEvent.where(status: 'Skipped Row').and(IngestEvent.where(reason: 'Skipping row [3] with parent oid: 2005513 because it was not found in local database')).count).to eq 0
        expect(IngestEvent.where(status: 'deleted').and(IngestEvent.where(reason: 'Parent 2005514 has been deleted')).count).to eq 1
        expect(IngestEvent.where(status: 'deleted').and(IngestEvent.where(reason: 'Parent 2005515 has been deleted')).count).to eq 1
        expect(ParentObject.all.count).to eq 0
      end
    end

  end

  context 'with perform inline' do
    it 'executes twice with no errors' do
      expect_any_instance_of(described_class).to receive(:perform).at_least(:once)
      expect_any_instance_of(described_class).to receive(:perform).exactly(2).times
      active_job = described_class.perform_later(delete_batch_process)
      10.times do
        GoodJob.perform_inline
        Timecop.travel(5.minutes)
      end
      Timecop.return

      good_job = GoodJob::Job.find_by(active_job_id: active_job.job_id)
      # byebug
      # expect(good_job.executions.count).to eq 2
      # expect(good_job.executions.last.error).to be_nil
    end
  end
end
