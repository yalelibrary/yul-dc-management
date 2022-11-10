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
Capybara.always_include_port = true
Capybara.app_host = "http://#{ENV['WEB_HOST']}:#{Capybara.server_port}"
Capybara.javascript_driver = :chrome

# Setup rspec
RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    # rails system specs reset app_host each time so needs to be forced on each test
    Capybara.app_host = "http://#{ENV['WEB_HOST']}:#{Capybara.server_port}"
    driven_by :chrome
  end
end

# @TODO Remove this Monkey Patch after issue is resolved with running Chrome 74 in
#       headless mode: https://github.com/teamcapybara/capybara/issues/2181
module Selenium
  module WebDriver
    class Options
      # capybara/rspec installs a RSpec callback that runs after each test and resets
      # the session - part of which is deleting all cookies. However the call to Chrome
      # Webdriver to delete all cookies in Chrome 74 hangs when run in headless mode
      # (the reasons for which are still unknown).
      #
      # Fortunately, the call to set a cookie is still functioning and we can rely
      # on expired cookies being cleared by Chrome, so we iterate over all current
      # cookies and set their expiry date to some time in the past - effectively
      # deleting them.
      def delete_all_cookies
        all_cookies.each do |cookie|
          add_cookie(name: cookie[:name], value: '', expires: Time.zone.now - 1.second)
        end
      end
    end
  end
end
