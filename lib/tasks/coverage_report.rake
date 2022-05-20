# frozen_string_literal: true

require 'simplecov_json_formatter'
require 'simplecov_small_badge'

namespace :coverage do
  task report: :environment do
    require 'simplecov'

    SimpleCov.collate Dir["coverage_results/.resultset-*.json"], 'rails' do
      formatter SimpleCov::Formatter::MultiFormatter.new(
        [
          SimpleCov::Formatter::JSONFormatter,
          SimpleCov::Formatter::HTMLFormatter,
          SimpleCovSmallBadge::Formatter
        ]
      )
    end
  end
end
