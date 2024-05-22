# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UpdatePermissionRequestsJob, type: :job, prep_metadata_sources: true, js: true do
  let(:sysadmin) { FactoryBot.create(:sysadmin_user) }
  let(:user) { FactoryBot.create(:user) }
  let(:admin_set) { FactoryBot.create(:admin_set) }
  let(:request_user) { FactoryBot.create(:permission_request_user, sub: "sub 1", name: "name 1", netid: "netid", email: "email@example.com") }
  let(:permission_set) { FactoryBot.create(:permission_set, label: "set 1", key: 'key 1') }
  let(:parent_object) { FactoryBot.create(:parent_object, oid: "2002826", admin_set_id: admin_set.id) }
  # rubocop:disable Layout/LineLength
  let(:permission_request) do
    FactoryBot.create(:permission_request, request_status: "Approved", permission_set: permission_set, parent_object: parent_object, permission_request_user: request_user, user_note: 'something', permission_request_user_name: 'name 2', access_until: "2020-06-10 00:00:00")
  end
  # rubocop:enable Layout/LineLength

  before do
    permission_request
    allow(GoodJob).to receive(:preserve_job_records).and_return(true)
    ActiveJob::Base.queue_adapter = GoodJob::Adapter.new(execution_mode: :inline)
  end

  describe "update permission requests job" do
    it "will update request_status to expired" do
      expect(OpenWithPermission::PermissionRequest.first.request_status).to eq "Approved"
      UpdatePermissionRequestsJob.perform_now
      expect(OpenWithPermission::PermissionRequest.first.request_status).to eq "Expired"
    end
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
      expect(GoodJob::CronEntry.all.last.instance_variable_get(:@params)).to eq({ cron: "15 0 * * *", class: "UpdatePermissionRequestsJob", key: :update_permission_requests })
    end
  end
end
