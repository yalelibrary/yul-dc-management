# frozen_string_literal: true
class OidMinterController < ActionController::Base
  # Allowing unauthenticated access
  # before_action :authenticate_user!

  def generate_oids
    number = params[:number]
    number ||= 1
    if an_integer?(number)
      oids = OidMinterService.generate_oids(number.to_i)
      respond_to do |format|
        format.json { render json: { oids: oids } }
        format.text { render plain: oids.join("\n") }
        format.any(:html) { render plain: "Please request text/plain or application/json content types.", status: :not_acceptable }
      end
      oid_request_info = { ip_address: request.remote_ip.to_s, oids: oids.to_s }
      Rails.logger.info("OIDs Created: #{oid_request_info.to_json}")
    else
      render plain: "Invalid request, please supply an integer value", status: :bad_request
    end
  end

  def an_integer?(number)
    number.to_s !~ /\D/
  end
end
