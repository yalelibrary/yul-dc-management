# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UpdateFulltextStatusJob, type: :job, solr: true do
  let(:admin_set) { FactoryBot.create(:admin_set, id: 1) }
  let(:parent_object) { FactoryBot.build(:parent_object, oid: '16797069', admin_set: admin_set) }

  context 'with test active job queue' do
    def queue_adapter_for_test
      ActiveJob::QueueAdapters::DelayedJobAdapter.new
    end

    it 'increments the job queue by one' do
      parent_object
      ActiveJob::Base.queue_adapter = :delayed_job
      expect do
        UpdateFulltextStatusJob.perform_later
      end.to change { Delayed::Job.count }.by(1)
    end
  end

  context 'batch process' do
    let(:user) { FactoryBot.create(:user) }
    let(:role) { FactoryBot.create(:role, name: editor) }
    let(:batch_process) { FactoryBot.create(:batch_process, user: user, batch_action: 'update fulltext status') }
    let(:metadata_source) { FactoryBot.create(:metadata_source) }
    let(:parent_object) { FactoryBot.create(:parent_object, oid: 2_004_628, authoritative_metadata_source: metadata_source, admin_set_id: admin_set.id) }
    let(:child_object) { FactoryBot.create(:child_object, oid: 456_789, parent_object: parent_object) }

    before do
      child_object
    end

    around do |example|
      perform_enqueued_jobs do
        example.run
      end
    end

    it "updates fulltext status for all parents" do
      user.add_role(:editor, admin_set)
      expect(batch_process).to receive(:oids).and_return(['2004628'])
      expect(ParentObject).to receive(:find_by).and_return(parent_object).twice
      expect(parent_object).to receive(:processing_event).twice # for queued and then completed message
      expect(parent_object).to receive(:update_fulltext_for_children).once # called because permission
      UpdateFulltextStatusJob.perform_now(batch_process)
    end

    it "skips parents when user does not have permissions" do
      expect(batch_process).to receive(:oids).and_return(['2004628']).twice
      expect(BatchProcess).to receive(:find).and_return(batch_process)
      expect(batch_process).to receive(:batch_processing_event).once # for skipped row
      expect(ParentObject).to receive(:find_by).and_return(parent_object).twice
      expect(parent_object).not_to receive(:update_fulltext_for_children) # should not update
      UpdateFulltextStatusJob.perform_now(batch_process)
    end

    it "skips unknown parents" do
      expect(batch_process).to receive(:oids).and_return(['0101010']).once
      expect(batch_process).to receive(:batch_processing_event).once # for skipped row
      expect(ParentObject).to receive(:find_by).and_return(nil).once
      expect(parent_object).not_to receive(:update_fulltext_for_children) # should not update
      UpdateFulltextStatusJob.perform_now(batch_process)
    end
  end
end
