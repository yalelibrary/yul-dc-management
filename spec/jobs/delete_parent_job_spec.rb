# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DeleteParentObjectsJob, type: :job, prep_metadata_sources: true do
  let(:batch_process) { FactoryBot.create(:batch_process, user: FactoryBot.create(:user)) }

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
      limit = 50
      total_parent_object_count = 400
      # set up mocks for parent objects
      expect(batch_process).to receive(:delete_parent_objects).and_return([nil, [double]]).exactly(total_parent_object_count).times

      parent_object_order = double
      parent_object_order_offset1 = double
      parent_object_order_offset2 = double
      expect(ParentObject).to receive(:order).and_return(parent_object_order).exactly((total_parent_object_count.to_f / limit).ceil).times
      expect(parent_object_order).to receive(:offset).with(0).and_return parent_object_order_offset1
      expect(parent_object_order).to receive(:offset).with(limit).and_return parent_object_order_offset2
      expect(parent_object_order_offset1).to receive(:limit).with(limit).and_return [*1..limit].map { |_ix| batch_process }
      expect(parent_object_order_offset2).to receive(:limit).with(limit).and_return [*1..(total_parent_object_count - limit)].map { |_ix| batch_process }
    end

    around do |example|
      perform_enqueued_jobs do
        example.run
      end
    end

    it 'goes through all parents in batches' do
      DeleteParentObjectsJob.perform_later(batch_process)
    end
  end
end
