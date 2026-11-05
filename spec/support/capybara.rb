# frozen_string_literal: true
# TODO  Webdrivers.cache_time = 3
Capybara.default_max_wait_time = 8

# Setup chrome headless driver
# Capybara.server = :puma, { Silent: false }
ENV['WEB_HOST'] ||= `hostname -s`.strip

options = Selenium::WebDriver::Chrome::Options.new(args: %w[headless disable-gpu no-sandbox whitelisted-ips window-size=1200,1200 disable-dev-shm-usage])
options.add_argument(
  "--enable-features=NetworkService,NetworkServiceInProcess"
)
# Point the external font host at nothing so font requests fail instantly instead of hanging.
# A slow font host held up the page load event past Selenium's 60s read timeout, failing unrelated
# specs. Font availability is checked on its own in spec/requests/external_fonts_spec.rb.
options.add_argument("--host-resolver-rules=MAP static.library.yale.edu 127.0.0.1")

Capybara.register_driver :chrome do |app|
  d = Capybara::Selenium::Driver.new(app,
                                     browser: :remote,
                                     options: options,
                                     url: "http://chrome:4444/wd/hub")
  # Fix for capybara vs remote files. Selenium handles this for us
  d.browser.file_detector = lambda do |args|
    str = args.first.to_s
    str if File.exist?(str)
  end
  d
end
Capybara.server_host = '0.0.0.0'
Capybara.server_port = 3007
Capybara.always_include_port = true
Capybara.app_host = "http://#{ENV['WEB_HOST']}:#{Capybara.server_port}"
Capybara.javascript_driver = :chrome

Capybara.configure do |config|
  config.default_driver = :chrome
  config.javascript_driver = :chrome

  # Start a separate server for each app instance instead of sharing one across sessions
  config.reuse_server = false
end

# Quit browsers before dropping them from the pool. A browser that is dropped without quitting keeps
# its page and JS timers running in the Selenium container, and its requests keep hitting the test
# server during later specs.
def quit_and_clear_capybara_sessions
  Capybara.send(:session_pool).each_value do |session|
    session.driver.quit
  rescue StandardError => e
    warn "[Capybara] Unable to quit stale session: #{e.message}"
  end
  Capybara.send(:session_pool).clear
end

# Every Selenium retry during the run, reported at the end so a retry that ends in a pass can't
# hide a recurring problem.
module CapybaraRetryLog
  def self.entries
    @entries ||= []
  end
end

# Setup rspec
RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :chrome
  end

  config.before(:each, type: :system, js: true) do
    # rails system specs reset app_host each time so needs to be forced on each test
    Capybara.app_host = "http://#{ENV['WEB_HOST']}:#{Capybara.server_port}"
  end

  config.after(:each) do
    Capybara.reset_sessions!
  rescue Selenium::WebDriver::Error::InvalidSessionIdError,
         Selenium::WebDriver::Error::WebDriverError => e
    warn "[Capybara] Stale Selenium session on reset, clearing pool: #{e.message}"
    quit_and_clear_capybara_sessions
  end

  # Retry mechanism for Selenium session errors.
  # RSpec records an example's error on example.exception instead of raising it out of example.run,
  # so check the recorded exception rather than rescuing.
  config.around(:each) do |example|
    retries = 3
    loop do
      example.run
      error = example.exception
      break unless error.is_a?(Selenium::WebDriver::Error::WebDriverError) && retries > 0

      retries -= 1
      warn "[Capybara] Retrying example due to Selenium session error: #{error.message}"
      CapybaraRetryLog.entries << "#{example.location} (#{error.class})"
      Capybara.default_driver = :chrome
      quit_and_clear_capybara_sessions
      # Forget the failed attempt so the retry is judged on its own result
      example.example.instance_variable_set(:@exception, nil)
      example.example.display_exception = nil
      # Memoized lets from the failed attempt point at records the cleaner already removed
      example.example_group_instance.send(:__init_memoized)
    end
  end

  config.after(:suite) do
    entries = CapybaraRetryLog.entries
    next if entries.empty?
    # NOTE: an example retried more than once is listed once per retry
    warn "[Capybara] #{entries.size} Selenium retr#{entries.size == 1 ? 'y' : 'ies'} during this run:\n  #{entries.join("\n  ")}"
  end
end
