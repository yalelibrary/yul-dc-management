# frozen_string_literal: true
class OidMinterController < ApplicationController
  before_action :authenticate_user!

  def generate_oids
    number = params[:number]
    number ||= 1
    if an_integer?(number)
      oids = OidMinterService.generate_oids(number.to_i)
      respond_to do |format|
        format.json { render json: { oids: oids } }
        format.text { render plain: oids.join("\n") }
        format.any  { render plain: "Please request text/plain or application/json content types.", status: :not_acceptable }
      end
    else
      render plain: "Invalid request, please supply an integer value", status: :bad_request
    end
  end

  def an_integer?(number)
    number.to_s !~ /\D/
  end
end
