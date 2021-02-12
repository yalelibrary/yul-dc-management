# frozen_string_literal: true

# Very simple job.  Scan needs to occur in a job so that the mounts are available
class MetsDirectoryScanJob < ApplicationJob
  queue_as :default

  def default_priority
    100
  end

  def perform
    MetsDirectoryScanner.perform_scan
  end
end
