# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  config.rails_semantic_logger.semantic = false # turn off semantic logging conversion in dev
  config.colorize_logging = true # turn on fancy colorized logs in dev

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable server timing
  config.server_timing = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join('tmp', 'caching-dev.txt').exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true

  config.rails_semantic_logger.semantic = false # turn off semantic logging conversion in dev
  config.colorize_logging = true # turn on fancy colorized logs in dev

  # Devise action mailer default url
  config.action_mailer.default_url_options = { host: 'localhost', port: 3001 }

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log
  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  config.file_watcher = ActiveSupport::FileUpdateChecker

  # Set the initial value for the OID sequence.
  # The dev and test environments have very high starting values to distinguish from prod
  config.oid_sequence_initial_value = 300_000_000

  config.active_job.queue_adapter = :good_job

  config.web_console.allowed_ips = ["172.0.0.0/8", '192.168.0.0/16', '127.0.0.1']

  config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins ['https://iiif_tools.collections.library.yale.edu', /\Ahttp.*/]
      resource '*', headers: :any, methods: [:get, :post, :delete, :options], credentials: true
    end
  end
  config.action_mailer.delivery_method = :sendmail
  config.action_mailer.perform_deliveries = false
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.preview_path = Rails.root.join("spec", "mailers", "previews")
  config.action_mailer.deliver_later_queue_name = 'default'

  # for open with permission testing
  config.hosts << 'yul-dc_management_1'
  config.hosts << '0.0.0.0'
end
# rubocop:enable Metrics/BlockLength
