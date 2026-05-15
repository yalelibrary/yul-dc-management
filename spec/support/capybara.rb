# frozen_string_literal: true
# TODO  Webdrivers.cache_time = 3
Capybara.default_max_wait_time = 8
Capybara.default_driver = :rack_test

# Setup chrome headless driver
# Capybara.server = :puma, { Silent: false }
ENV['WEB_HOST'] ||= `hostname -s`.strip

options = Selenium::WebDriver::Chrome::Options.new(args: %w[headless disable-gpu no-sandbox whitelisted-ips window-size=1400,1400 disable-dev-shm-usage])
options.add_argument(
  "--enable-features=NetworkService,NetworkServiceInProcess"
)

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

  # Forces Capybara to handle server configurations isolatively per thread
  config.reuse_server = false
end

# Setup rspec
RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :chrome
  end

  config.before(:each, type: :system, js: true) do
    # rails system specs reset app_host each time so needs to be forced on each test
    Capybara.app_host = "http://#{ENV['WEB_HOST']}:#{Capybara.server_port}"
    driven_by :chrome
  end

  config.after(:each) do
    Capybara.reset_sessions!
  end

  # rubocop:disable Style/GuardClause
  # Retry mechanism for Selenium session errors
  config.around(:each, type: :system) do |example|
    retries = 2
    begin
      example.run
    rescue Selenium::WebDriver::Error::NoSuchSessionError, Selenium::WebDriver::Error::InvalidSessionIdError, Selenium::WebDriver::Error::UnknownError => e
      if retries > 0 && e.message =~ /session not found|unable to find session|invalid session id/i
        retries -= 1
        Capybara.reset_sessions!
        warn "[Capybara] Retrying example due to Selenium session error: #{e.message}"
        retry
      else
        raise
      end
    end
  end
  # rubocop:enable Style/GuardClause
end
