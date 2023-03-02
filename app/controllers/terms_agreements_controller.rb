# frozen_string_literal: true

class TermsAgreementsController < ApplicationController
  def create
    @terms_agreement = TermsAgreement.new(terms_agreement_params)

    respond_to do |format|
      if @terms_agreement.save
        format.html { redirect_to @terms_agreement, notice: 'Terms agreement was successfully created.' }
        format.json { render :show, status: :created, location: @terms_agreement }
      else
        format.html { render :new }
        format.json { render json: @terms_agreement.errors, status: :unprocessable_entity }
      end
    end
  end

  private

    # Only allow a list of trusted parameters through.
    def terms_agreement_params
      params.require(:terms_agreement).permit(:permission_request_user, :permission_set_term, :agreement_ts)
    end
end
