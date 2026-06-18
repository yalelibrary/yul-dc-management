# frozen_string_literal: true

module GoodJobAdapterHelper
  def with_good_job_external_mode
    original_queue_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = GoodJob::Adapter.new(execution_mode: :external)
    yield
  ensure
    ActiveJob::Base.queue_adapter = original_queue_adapter
  end
end
