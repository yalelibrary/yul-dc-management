# frozen_string_literal: true
initial_value = Rails.application.config.oid_sequence_initial_value
# Check for nulldb is required to avoid running this during Docker build
ActiveRecord::Base.connection.execute("CREATE SEQUENCE IF NOT EXISTS OID_SEQUENCE START WITH #{initial_value};") unless 'nulldb' == ENV['DB_ADAPTER']
