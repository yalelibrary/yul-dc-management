# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ChildObjectIntegrityCheckJob, type: :job do
  before do
    allow(GoodJob).to receive(:preserve_job_records).and_return(true)
    ActiveJob::Base.queue_adapter = GoodJob::Adapter.new(execution_mode: :external)
  end

  let(:child_object_integrity_check_job) { ChildObjectIntegrityCheckJob.new }

  it 'increments the job queue by one' do
    csv_job = described_class.perform_later
    expect(csv_job.instance_variable_get(:@successfully_enqueued)).to eq true
  end

  it "has correct priority" do
    expect(child_object_integrity_check_job.default_priority).to eq(-100)
  end

  it "has correct queue" do
    expect(child_object_integrity_check_job.queue_name).to eq('default')
  end

  it 'sets batch action to integrity check when performed' do
    child_object_integrity_check_job.perform
    expect(BatchProcess.first.batch_action).to eq 'integrity check'
  end

  it 'reports error when integrity_check fails' do
    allow_any_instance_of(BatchProcess).to receive(:integrity_check).and_raise('boom!')
    expect do
      child_object_integrity_check_job.perform
    end.to raise_error('boom!')
  end

  describe "jumping ahead one day" do
    before do
      Timecop.freeze(Time.zone.today)
    end

    after do
      Timecop.return
    end

    it "increments job queue once per day" do
      now = Time.zone.today
      new_time = now + 1.day
      Timecop.travel(new_time)
      expect(GoodJob::CronEntry.all[1].instance_variable_get(:@params)).to eq({ cron: "15 0 * * *", class: "ChildObjectIntegrityCheckJob", key: :integrity })
    end
  end
end
