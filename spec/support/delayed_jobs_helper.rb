# frozen_string_literal: true

module DelayedJobsHelper
  # Setup rspec
  RSpec.configure do |config|
    config.around(undelayed: true) do |example|
      Delayed::Worker.delay_jobs = false
      example.run
      Delayed::Worker.delay_jobs = true
    end
  end
end
