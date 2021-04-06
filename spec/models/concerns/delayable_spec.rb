# frozen_string_literal: true
require "rails_helper"

RSpec.describe Delayable, prep_metadata_sources: true, prep_admin_sets: true do
  let(:user) { FactoryBot.create(:user) }
  let(:batch_process) { BatchProcess.create(user_id: user.id) }
  let(:parent_object) { FactoryBot.build(:parent_object, oid: '16685691') }
  let!(:job) { Delayed::Job.create(handler: parent_object.to_gid)}

  describe 'delayed_jobs' do
    it 'returns delayed jobs associated with the parent object' do
      expect(parent_object.delayed_jobs).to include(job)
    end

    it 'can distinguish between SetupMetadaJobs and other job types'

    it 'will destroy all jobs from a given parent object when the parent object is destroyed'
  end
end
