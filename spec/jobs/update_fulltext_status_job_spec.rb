# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UpdateFulltextStatusJob, type: :job, prep_metadata_sources: true, prep_admin_sets: true, solr: true do
  before do
    allow(GoodJob).to receive(:preserve_job_records).and_return(true)
    ActiveJob::Base.queue_adapter = GoodJob::Adapter.new(execution_mode: :inline)
  end

  let(:admin_set) { AdminSet.first }
  let(:metadata_source) { MetadataSource.first }
  let(:parent_object) { FactoryBot.build(:parent_object, oid: '16797069', authoritative_metadata_source: metadata_source, admin_set: admin_set) }

  context 'with test active job queue' do
    it 'increments the job queue by one' do
      parent_object
      fulltext_job = described_class.perform_later
      expect(fulltext_job.instance_variable_get(:@successfully_enqueued)).to eq true
    end
  end

  context 'batch process' do
    let(:user) { FactoryBot.create(:user) }
    let(:role) { FactoryBot.create(:role, name: editor) }
    let(:batch_process) { FactoryBot.create(:batch_process, user: user, batch_action: 'update fulltext status') }
    let(:parent_object) { FactoryBot.create(:parent_object, oid: 2_004_628, authoritative_metadata_source: metadata_source, admin_set: admin_set) }
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
      expect(AdminSet).to receive(:find).and_return(admin_set)
      expect(parent_object).to receive(:processing_event).twice # for queued and then completed message
      expect(parent_object).to receive(:update_fulltext).once # called because permission
      UpdateFulltextStatusJob.perform_now(batch_process)
    end

    it "skips parents when user does not have permissions" do
      user.remove_role(:editor, admin_set)
      expect(batch_process).to receive(:oids).and_return(['2004628']).twice
      expect(BatchProcess).to receive(:find).and_return(batch_process)
      expect(batch_process).to receive(:batch_processing_event).once # for skipped row
      expect(ParentObject).to receive(:find_by).and_return(parent_object).twice
      expect(parent_object).not_to receive(:update_fulltext) # should not update
      UpdateFulltextStatusJob.perform_now(batch_process)
    end

    it "skips unknown parents" do
      expect(batch_process).to receive(:oids).and_return(['0101010']).once
      expect(batch_process).to receive(:batch_processing_event).once # for skipped row
      expect(ParentObject).to receive(:find_by).and_return(nil).once
      expect(parent_object).not_to receive(:update_fulltext) # should not update
      UpdateFulltextStatusJob.perform_now(batch_process)
    end
  end
end
