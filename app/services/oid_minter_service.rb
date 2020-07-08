# frozen_string_literal: true
#
class OidMinterService
  def self.generate_oids(number)
    oids = []
    number.times do
      result = ActiveRecord::Base.connection.execute("SELECT NEXTVAL('OID_SEQUENCE')")
      oids.push result.getvalue(0, 0)
    end
    oids
  end

  def self.initialize_sequence!
    initial_value = Rails.application.config.oid_sequence_initial_value
    sql = "CREATE SEQUENCE IF NOT EXISTS OID_SEQUENCE START WITH #{initial_value};"
    is_nulldb = ActiveRecord::Base.connection.instance_of?(ActiveRecord::ConnectionAdapters::NullDBAdapter)
    ActiveRecord::Base.connection.execute(sql) unless is_nulldb
  end
end
