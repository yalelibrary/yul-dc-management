# frozen_string_literal: true
# TODO  Webdrivers.cache_time = 3
Capybara.default_max_wait_time = 8
Capybara.default_driver = :rack_test

# Setup chrome headless driver
# Capybara.server = :puma, { Silent: false }
ENV['WEB_HOST'] ||= `hostname -s`.strip

capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
  chromeOptions: {
    args: %w[disable-gpu no-sandbox whitelisted-ips window-size=1400,1400]
  }
)

Capybara.register_driver :chrome do |app|
  d = Capybara::Selenium::Driver.new(app,
    browser: :remote,
    desired_capabilities: capabilities,
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
Capybara.app_host = "http://#{ENV['WEB_HOST']}:#{Capybara.server_port}"

# Capybara.register_driver :chrome_headless do |app|
#   capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
#     chromeOptions: {
#       args: %w[headless disable-dev-shm-usage disable-gpu no-sandbox whitelisted-ips window-size=1400,1400]
#     }
#   )

#   client = Selenium::WebDriver::Remote::Http::Default.new
#   client.read_timeout = 120

#   d = Capybara::Selenium::Driver.new(app,
#     browser: :remote,
#     desired_capabilities: capabilities,
#     url: "http://chrome:4444/wd/hub",
#     http_client: client)

#   # Fix for capybara vs remote files. Selenium handles this for us
#   d.browser.file_detector = lambda do |args|
#     str = args.first.to_s
#     str if File.exist?(str)
#   end
#   d
# end

# Capybara.server_host = '0.0.0.0'
# Capybara.server_port = 3001
# Capybara.app_host = "http://#{ENV['WEB_HOST']}:#{Capybara.server_port}"

Capybara.javascript_driver = :chrome

# Setup rspec
RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    driven_by :chrome
  end
end
