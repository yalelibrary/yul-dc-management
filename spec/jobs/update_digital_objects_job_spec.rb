# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UpdateDigitalObjectsJob, type: :job, prep_metadata_sources: true, solr: true do
  let(:parent_object) { FactoryBot.build(:parent_object, oid: '16797069') }
  let(:admin_set_1) { FactoryBot.create(:admin_set) }

  before do
    allow(GoodJob).to receive(:preserve_job_records).and_return(true)
    ActiveJob::Base.queue_adapter = GoodJob::Adapter.new(execution_mode: :inline)
  end

  context 'with tests active job queue' do
    it 'increments the job queue by one' do
      parent_object
      digital_job = described_class.perform_later
      expect(digital_job.instance_variable_get(:@successfully_enqueued)).to eq true
    end
  end

  context 'with feature flag on' do
    before do
      allow(UpdateDigitalObjectsJob).to receive(:job_limit).and_return(2)
      allow(SetupMetadataJob).to receive(:perform_later) # this is just to prevent errors trying to get metadata
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

    context 'without digital object json' do
      let(:po1) { FactoryBot.create(:parent_object, oid: '000000001', admin_set_id: admin_set_1.id) }
      before do
        allow(UpdateDigitalObjectsJob).to receive(:job_limit).and_return(2)
        allow(SetupMetadataJob).to receive(:perform_later) # this is just to prevent errors trying to get metadata
        po1
      end
      it 'does not send digital object updates' do
        expect(HTTP).to receive(:basic_auth).exactly(0).times
        UpdateDigitalObjectsJob.perform_later(admin_set_1.id)
      end
    end
    context 'with digital object json' do
      let(:po1) { FactoryBot.create(:parent_object, oid: '000000001', admin_set_id: admin_set_1.id) }
      let(:digital_object_json1) { FactoryBot.create(:digital_object_json, parent_object: po1) }
      before do
        allow(UpdateDigitalObjectsJob).to receive(:job_limit).and_return(2)
        allow(SetupMetadataJob).to receive(:perform_later) # this is just to prevent errors trying to get metadata
        po1
        digital_object_json1
      end
      it 'does not send digital object updates' do
        http = double
        expect(http).to receive(:post).exactly(1).times
        expect(HTTP).to receive(:basic_auth).exactly(1).times.and_return(http)
        UpdateDigitalObjectsJob.perform_later(admin_set_1.id)
      end
    end
  end

  context 'with more than limit parent objects' do
    let(:po1) { FactoryBot.create(:parent_object, oid: '000000001', admin_set_id: admin_set_1.id) }
    let(:po2) { FactoryBot.create(:parent_object, oid: '000000002', admin_set_id: admin_set_1.id) }
    let(:po3) { FactoryBot.create(:parent_object, oid: '000000003', admin_set_id: admin_set_1.id) }
    let(:digital_object_json1) { FactoryBot.create(:digital_object_json, parent_object: po1) }
    let(:digital_object_json2) { FactoryBot.create(:digital_object_json, parent_object: po2) }
    let(:digital_object_json3) { FactoryBot.create(:digital_object_json, parent_object: po3) }
    let(:total_records) { 3 }
    let(:limit) { UpdateDigitalObjectsJob.job_limit }

    before do
      allow(UpdateDigitalObjectsJob).to receive(:job_limit).and_return(2)
      allow(SetupMetadataJob).to receive(:perform_later) # this is just to prevent errors trying to get metadata
      po1
      po2
      po3
      digital_object_json1
      digital_object_json2
      digital_object_json3
    end

    around do |example|
      original_vpn = ENV['VPN']
      ENV['VPN'] = 'true'
      perform_enqueued_jobs do
        example.run
      end
      ENV['VPN'] = original_vpn
    end

    context 'feature flag is set' do
      around do |example|
        original_ff = ENV['FEATURE_FLAGS']
        ENV['FEATURE_FLAGS'] = '|DO-SEND|'
        perform_enqueued_jobs do
          example.run
        end
        ENV['FEATURE_FLAGS'] = original_ff
      end

      it 'sends all digital object updates' do
        http = double
        expect(http).to receive(:post).exactly(3).times
        expect(HTTP).to receive(:basic_auth).exactly(3).times.and_return(http)
        UpdateDigitalObjectsJob.perform_later(admin_set_1.id)
      end
    end

    context 'when feature flag is not set' do
      around do |example|
        original_ff = ENV['FEATURE_FLAGS']
        ENV['FEATURE_FLAGS'] = '|x|'
        perform_enqueued_jobs do
          example.run
        end
        ENV['FEATURE_FLAGS'] = original_ff
      end

      it 'does not send updates' do
        expect(HTTP).not_to receive(:basic_auth)
        UpdateDigitalObjectsJob.perform_later(admin_set_1.id)
      end
    end
  end
end
