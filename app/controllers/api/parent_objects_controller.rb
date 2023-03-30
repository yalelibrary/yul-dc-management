# frozen_string_literal: true

class Api::ParentObjectsController < ApplicationController
  skip_before_action :authenticate_user!

  def retrieve_metadata
    return unless parent_found
    return unless parent_visibility_valid(@parent_object)
    render json: @parent_object.dcs_metadata, status: 200
  end

  def parent_found
    begin
      @parent_object = ParentObject.find(params['oid'].to_i)
    rescue ActiveRecord::RecordNotFound
      render(json: { "title": "Invalid Parent OID" }, status: 404) && (return false)
    end
    @parent_object
  end

  def parent_visibility_valid(parent_object)
    render(json: { "title": "Parent Object is restricted." }, status: 403) && (return false) unless
    parent_object.visibility == "Public" || parent_object.visibility == "Yale Community Only"
    true
  end

  private

    def parent_object_params
      params.require(:parent_object).permit(:oid)
    end
end
