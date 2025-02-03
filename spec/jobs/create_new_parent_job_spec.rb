# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CreateNewParentJob, type: :job, prep_metadata_sources: true, prep_admin_sets: true do
  let(:admin_set) { AdminSet.find_by(key: 'brbl') }
  let(:user) { FactoryBot.create(:user) }
  let(:create_many) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "create_many_parent_fixture_ids.csv")) }
  let(:create_batch_process) { FactoryBot.create(:batch_process, user: user, file: create_many) }
  let(:bare_create_batch_process) { FactoryBot.create(:batch_process, user: user) }
  let(:total_parent_object_count) { 4 }

  before do
    allow(GoodJob).to receive(:preserve_job_records).and_return(true)
    ActiveJob::Base.queue_adapter = GoodJob::Adapter.new(execution_mode: :inline)
  end

  it 'increments the job queue by one' do
    create_parent_job = described_class.perform_later(bare_create_batch_process)
    expect(create_parent_job.instance_variable_get(:@successfully_enqueued)).to eq true
  end

  context 'with more than limit of batch objects' do
    before do
      BatchProcess::BATCH_LIMIT = 2
      expect(ParentObject.all.count).to eq 0
      user.add_role(:editor, admin_set)
      login_as(:user)
      expect(described_class).to receive(:perform_later).exactly(2).times.and_call_original
    end

    around do |example|
      perform_enqueued_jobs do
        example.run
      end
    end

    it 'goes through all parents in batches once' do
      create_batch_process.save
      expect(ParentObject.all.count).to eq total_parent_object_count
      expect(IngestEvent.where(reason: 'Processing has been queued').count).to eq total_parent_object_count
    end
  end
end
