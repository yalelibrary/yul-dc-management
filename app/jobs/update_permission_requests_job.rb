# frozen_string_literal: true

class UpdatePermissionRequestsJob < ApplicationJob
  queue_as :default

  def default_priority
    100
  end

  def perform
    permission_requests = OpenWithPermission::PermissionRequest.all
    permission_requests.each do |pr|
      next if pr.access_until.nil? || pr.request_status != "Approved"
      if pr.access_until < Time.zone.now
        pr.request_status = "Expired"
        pr.save!
      end
    end
  end
end
