# frozen_string_literal: true

class DownloadOriginalController < ApplicationController
  skip_before_action :authenticate_user!

  def stage
    request = params
    begin
      child_object = ChildObject.find(request['oid'].to_i)
    rescue ActiveRecord::RecordNotFound
      Rails.logger.error "Child object with oid: #{request['oid']} not found."
      render(json: { "title": "Invalid Child OID" }, status: 400) && (return false)
    end
    return unless check_child_visibility(child_object)
    SaveOriginalToS3Job.perform_later(child_object.oid)
    render(json: { "title": "Child object staged for download." }, status: 200)
  end

  def check_child_visibility(child_object)
    render(json: { "title": "Child Object is restricted." }, status: 403) && (return false) unless
    child_object.parent_object.visibility == "Public" || child_object.parent_object.visibility == "Yale Community Only"
    true
  end

  private

    def download_original_params
      params.require(:download_original).permit(:oid)
    end
end
