# frozen_string_literal: true
require "rails_helper"

RSpec.describe Delayable, prep_metadata_sources: true, prep_admin_sets: true do
  let(:parent_object) { FactoryBot.build(:parent_object, oid: '16685691') }
  let!(:job) { Delayed::Job.create(handler: parent_object.to_gid) }
  let!(:setup_job) { Delayed::Job.create(handler: "job_class: SetupMetadataJob\n#{parent_object.to_gid}") }
  let!(:reindex_job) { Delayed::Job.create(handler: "job_class: SolrReindexAllJob\n") }

  describe 'delayed_jobs' do
    it 'returns delayed jobs associated with the parent object' do
      expect(parent_object.delayed_jobs).to include(job)
    end

    it 'can distinguish between SetupMetadaJobs and other job types' do
      expect(Delayed::Job.count).to eq 3
      expect(parent_object.setup_metadata_jobs.count).to eq 1
      expect(parent_object.setup_metadata_jobs.first).to eq setup_job
      expect(described_class.solr_reindex_jobs.count).to eq 1
      expect(described_class.solr_reindex_jobs.first).to eq reindex_job
    end

    it 'will destroy all jobs from a given parent object when the parent object is destroyed' do
      expect(parent_object.delayed_jobs.count).to eq 2
      parent_object.destroy
      expect(parent_object.delayed_jobs.count).to eq 0
    end
  end
end
