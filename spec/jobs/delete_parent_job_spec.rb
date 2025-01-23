# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DeleteParentObjectsJob, type: :job, prep_metadata_sources: true, prep_admin_sets: true do
  let(:admin_set) { AdminSet.find_by(key: 'brbl') }
  let(:user) { FactoryBot.create(:user) }
  let(:create_many) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "create_many_parent_fixture_ids.csv")) }
  let(:delete_many) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "delete_many_parent_fixture_ids.csv")) }
  let(:create_batch_process) { FactoryBot.create(:batch_process, user: user, file: create_many) }
  let(:delete_batch_process) { FactoryBot.create(:batch_process, user: user, file: delete_many, batch_action: 'delete parent objects') }

  context 'with tests active job queue' do
    before do
      allow(GoodJob).to receive(:preserve_job_records).and_return(true)
      ActiveJob::Base.queue_adapter = GoodJob::Adapter.new(execution_mode: :inline)
    end

    it 'increments the job queue by one' do
      delete_parent_job = described_class.perform_later
      expect(delete_parent_job.instance_variable_get(:@successfully_enqueued)).to be true
    end
  end

  context 'with more than limit parent objects' do
    before do
      expect(ParentObject.all.count).to eq 0
      Deletable::BATCH_LIMIT = 2
      user.add_role(:editor, admin_set)
      login_as(:user)
      create_batch_process.save
      total_parent_object_count = 4
      expect(ParentObject.all.count).to eq total_parent_object_count
      expect(delete_batch_process).to receive(:delete_parent_objects).with(0).exactly(1).times
    end

    around do |example|
      perform_enqueued_jobs do
        example.run
      end
    end

    it 'goes through all parents in batches' do
      DeleteParentObjectsJob.perform_now(delete_batch_process)
      expect(ParentObject.all.count).to eq 0
    end
  end
end
