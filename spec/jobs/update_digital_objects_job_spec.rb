# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UpdateDigitalObjectsJob, type: :job, prep_metadata_sources: true, solr: true do
  let(:parent_object) { FactoryBot.build(:parent_object, oid: '16797069') }
  let(:admin_set_1) { FactoryBot.create(:admin_set) }

  context 'with tests active job queue' do
    def queue_adapter_for_test
      ActiveJob::QueueAdapters::DelayedJobAdapter.new
    end

    it 'increments the job queue by one' do
      ActiveJob::Base.queue_adapter = :delayed_job
      expect do
        UpdateDigitalObjectsJob.perform_later
      end.to change { Delayed::Job.count }.by(1)
    end
  end

  context 'with more than limit parent objects' do
    let(:po1) { FactoryBot.create(:parent_object, oid: '000000001', admin_set_id: admin_set_1.id) }
    let(:po2) { FactoryBot.create(:parent_object, oid: '000000002', admin_set_id: admin_set_1.id) }
    let(:po3) { FactoryBot.create(:parent_object, oid: '000000003', admin_set_id: admin_set_1.id) }
    let(:total_records) { 3 }
    let(:limit) { UpdateDigitalObjectsJob.job_limit }

    before do
      allow(UpdateDigitalObjectsJob).to receive(:job_limit).and_return(2)
      allow(GeneratePtiffJob).to receive(:perform_later) # this is just to prevent errors trying to generate the ptiffs
      po1
      po2
      po3
    end

    around do |example|
      original_vpn = ENV['VPN']
      ENV['VPN'] = 'true'
      original_ff = ENV['FEATURE_FLAGS']
      ENV['FEATURE_FLAGS'] = '|DO-SEND|'
      perform_enqueued_jobs do
        example.run
      end
      ENV['VPN'] = original_vpn
      ENV['FEATURE_FLAGS'] = original_ff
    end

    it 'processes all parents in batches' do
      http = double
      expect(http).to receive(:post).exactly(3).times
      expect(HTTP).to receive(:basic_auth).exactly(3).times.and_return(http)
      UpdateDigitalObjectsJob.perform_later(admin_set_1.id)
    end
  end
end
