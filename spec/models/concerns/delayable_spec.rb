# frozen_string_literal: true
require "rails_helper"

RSpec.describe Delayable, prep_metadata_sources: true, prep_admin_sets: true do
  let(:parent_object) { FactoryBot.build(:parent_object, oid: '16685691', admin_set: AdminSet.first) }
  let!(:csv_job) { GoodJob::Job.create(job_class: "CreateParentOidCsvJob", serialized_params: { "arguments" => [{ "_aj_globalid" => "gid://yul-dc-management/ParentObject/16685691" }] }) }
  let!(:setup_job) { GoodJob::Job.create(job_class: "SetupMetadataJob", serialized_params: { "arguments" => [{ "_aj_globalid" => "gid://yul-dc-management/ParentObject/16685691" }] }) }
  let!(:reindex_job) { GoodJob::Job.create(job_class: "SolrReindexAllJob") }

  describe 'delayed_jobs' do
    it 'returns delayed jobs associated with the parent object' do
      expect(parent_object.delayed_jobs.first['job_class']).to eq('CreateParentOidCsvJob')
    end

    it 'can distinguish between SetupMetadaJobs and other job types' do
      expect(GoodJob::Job.count).to eq 3
      expect(parent_object.setup_metadata_jobs.count).to eq 1
      expect(parent_object.setup_metadata_jobs.first['job_class']).to eq('SetupMetadataJob')
      expect(Delayable.active_solr_reindex_jobs.count).to eq 1
      expect(Delayable.active_solr_reindex_jobs.first['job_class']).to eq('SolrReindexAllJob')
    end

    it 'will destroy all jobs from a given parent object when the parent object is destroyed' do
      expect(parent_object.delayed_jobs.count).to eq 2
      parent_object.destroy
      expect(parent_object.delayed_jobs.count).to eq 0
    end
  end
end
