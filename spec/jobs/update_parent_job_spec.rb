# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UpdateParentObjectsJob, type: :job do
  let(:user) { FactoryBot.create(:user) }
  let(:batch_process) { FactoryBot.create(:batch_process, batch_action: 'update parent objects', user: user) }

  it 'increments the job queue by one' do
    update_parent_job = described_class.perform_later(batch_process)
    expect(update_parent_job.instance_variable_get(:@successfully_enqueued)).to eq true
  end

  it "has correct priority" do
    update_parent_job = described_class.new
    expect(update_parent_job.default_priority).to eq(60)
  end
end
