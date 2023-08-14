# frozen_string_literal: true

module DelayedJobsHelper
  # Setup rspec
  RSpec.configure do |config|
    config.around(undelayed: true) do |example|
      GoodJob::Worker.delay_jobs = false
      example.run
      GoodJob::Worker.delay_jobs = true
    end
  end
end
