# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UpdateManifestsJob, type: :job, prep_metadata_sources: true, solr: true do
  let(:user) { FactoryBot.create(:sysadmin_user) }
  let(:admin_set) { FactoryBot.create(:admin_set, key: 'brbl') }
  let(:csv_admin_set) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "valid_admin_set.csv")) }
  let(:csv_invalid_admin_set) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "invalid_admin_set.csv")) }
  let(:parent_object) { FactoryBot.create(:parent_object, oid: "2002826", visibility: "Public", admin_set_id: admin_set.id) }
  let(:parent_object_2) { FactoryBot.create(:parent_object, oid: "200200", visibility: "Public", admin_set_id: admin_set.id) }

  context 'with tests active job queue' do
    def queue_adapter_for_test
      ActiveJob::QueueAdapters::DelayedJobAdapter.new
    end

    it 'increments the job queue by one' do
      ActiveJob::Base.queue_adapter = :delayed_job
      expect do
        UpdateManifestsJob.perform_later
      end.to change { Delayed::Job.count }.by(1)
    end
  end

  context 'when parent object count is udner limit' do
    it 'does things' do
    
    end
  end
end
