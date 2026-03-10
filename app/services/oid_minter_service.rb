# frozen_string_literal: true
#
class OidMinterService
  def self.generate_oids(number)
    oids = []
    initialize_sequence!
    number.times do
      result = ActiveRecord::Base.connection.execute("SELECT NEXTVAL('OID_SEQUENCE')")
      oids.push result.getvalue(0, 0)
    end
    oids
  end

  def self.initialize_sequence!
    initial_value = Rails.application.config.oid_sequence_initial_value
    # This does nothing if the sequence already exists
    ActiveRecord::Base.connection.execute("CREATE SEQUENCE IF NOT EXISTS OID_SEQUENCE START WITH #{initial_value};")
    initial_value
  end
end
