# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Reduces boot times through caching; required in config/boot.rb
gem 'activerecord-nulldb-adapter'
# Reoccurring jobs
gem 'activejob-scheduler', git: 'https://github.com/yalelibrary/activejob-scheduler', branch: 'main'
gem 'ajax-datatables-rails'
gem "aws-sdk-cloudwatch"
gem 'aws-sdk-s3'
gem 'bootsnap', '>= 1.4.2', require: false
gem 'bootstrap', '~> 4.5'
gem 'coderay', '~> 1.1', '>= 1.1.3'
gem 'devise'
gem 'github_changelog_generator'
gem "good_job", "~> 3.17"
gem 'honeybadger', '~> 4.0'
gem 'http', '~> 4.4', '>= 4.4.1'
gem 'iiif-presentation', '~> 1.0'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.7'
gem 'jquery-rails', '~> 4.4'
gem 'kaminari'
gem 'noticed', '~> 1.2', '>= 1.2.15'
gem 'omniauth'
gem 'omniauth-cas'
# This addresses CVE-2015-9284 https://github.com/advisories/GHSA-ww4x-rwq6-qpgf
gem 'cancancan'
gem 'omniauth-rails_csrf_protection', '~> 0.1'
gem 'rolify'
# Audit trail for changes to ActiveRecord models
gem 'paper_trail'
# Yale-specific pairtree gem
gem 'partridge', '~> 0.1.2'
# Use postgresql as the database for Active Record
gem 'pg', '>= 0.18', '< 2.0'
# Use Puma as the app server
gem 'puma', '~> 4.3'
# cors support or rack
gem 'rack-cors'
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 7.0.1'
gem "rails_semantic_logger", ">=4.4.4"
# Use rsolr to connect to Solr
gem 'rsolr', '~> 2.3'
# Use SCSS for stylesheets
gem 'sass-rails', '>= 6'
gem 'sprockets-rails'
gem 'string-direction'

# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
gem 'webpacker'

gem 'daemons'

gem 'jwt'

# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

group :development, :test do
  gem "amazing_print", ">=1.2.1" # colorized logging
  # Using Bixby for style for consistency with Blacklight application(s)
  gem 'bixby'
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'factory_bot_rails'
  gem 'rspec-rails', '~> 5.0.0'
  gem 'vcr', '~> 6.0'
  gem 'webmock', '~> 3.8', '>= 3.8.3'
end

group :development do
  gem 'listen', '~> 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 3.3.0'
end

group :test do
  gem 'capybara', '>= 2.15'
  gem 'coveralls_reborn', require: false
  gem 'ffaker'
  gem 'selenium-webdriver'
  gem 'shoulda-matchers', '~> 4.0'
  gem 'timecop'
  gem 'webdrivers', require: false
end
