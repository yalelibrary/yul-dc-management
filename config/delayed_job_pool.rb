# frozen_string_literal: true

# rubocop:disable Rails/Output
worker_group do |g|
  g.workers = Integer(ENV['WORKER_COUNT'].presence || 1)
  g.queues = (ENV['WORKER_QUEUES'].presence || 'default,manifest,ptiff,zeros,metadata,solr_index,pdf').split(',')
  g.sleep_delay = ENV['WORKER_SLEEP_DELAY']
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
