# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UpdateParentObjectsJob, type: :job do
  before do
    allow(GoodJob).to receive(:preserve_job_records).and_return(true)
    ActiveJob::Base.queue_adapter = GoodJob::Adapter.new(execution_mode: :inline)
  end
  let(:user) { FactoryBot.create(:user) }
  let(:batch_process) { FactoryBot.create(:batch_process, batch_action: 'update parent objects', user: user) }

  it 'increments the job queue by one' do
    update_parent_job = described_class.perform_later(batch_process)
    expect(update_parent_job.instance_variable_get(:@successfully_enqueued)).to eq true
  end
end
