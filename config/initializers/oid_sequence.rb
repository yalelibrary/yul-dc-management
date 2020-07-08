# frozen_string_literal: true

# Initializes the OID sequence if it does not exist
if Rails.application.config.respond_to?(:oid_sequence_initial_value)
  initial_value = Rails.application.config.oid_sequence_initial_value
  ActiveRecord::Base.connection.execute("CREATE SEQUENCE IF NOT EXISTS OID_SEQUENCE START WITH #{initial_value};")
end
