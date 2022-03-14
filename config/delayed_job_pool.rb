# frozen_string_literal: true

# rubocop:disable Rails/Output
# Rails helpers are not available at this point of loading the application
worker_group do |g|
  # rubocop:disable Style/TernaryParentheses,Style/ZeroLengthPredicate,Style/NumericPredicate
  worker_count = (ENV['WORKER_COUNT'] && ENV['WORKER_COUNT'].size > 0) ? ENV['WORKER_COUNT'] : 1
  g.workers = Integer(worker_count)
  worker_queue = (ENV['WORKER_QUEUES'] && ENV['WORKER_QUEUES'].size > 0) ? ENV['WORKER_QUEUES'] : 'default,manifest,ptiff,zeros,metadata,solr_index,pdf,intensive_solr_index'
  g.queues = worker_queue.split(',')
  sleep_delay = (ENV['WORKER_SLEEP_DELAY'] && ENV['WORKER_SLEEP_DELAY'].size > 0) ? ENV['WORKER_SLEEP_DELAY'] : 5
  g.sleep_delay = Integer(sleep_delay)
  # rubocop:enable Style/TernaryParentheses,Style/ZeroLengthPredicate,Style/NumericPredicate
end

preload_app

# This runs in the master process after it preloads the app
after_preload_app do
  puts "Master #{Process.pid} preloaded app"

  # Don't hang on to database connections from the master after we've
  # completed initialization
  ActiveRecord::Base.connection_pool.disconnect!
end

# This runs in the worker processes after it has been forked
on_worker_boot do |_worker_info|
  puts "Worker #{Process.pid} started"

  # Reconnect to the database
  ActiveRecord::Base.establish_connection
end

# This runs in the master process after a worker starts
after_worker_boot do |worker_info|
  puts "Master #{Process.pid} booted worker #{worker_info.name} with " \
        "process id #{worker_info.process_id}"
end

# This runs in the master process after a worker shuts down
after_worker_shutdown do |worker_info|
  puts "Master #{Process.pid} detected dead worker #{worker_info.name} " \
        "with process id #{worker_info.process_id}"
end
# rubocop:enable Rails/Output
