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
end
