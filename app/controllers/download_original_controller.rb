# frozen_string_literal: true

class DownloadOriginalController < ApplicationController
  def stage
    byebug
    request = params
    begin
      child_object = ChildObject.find(request['oid'].to_i)
    rescue ActiveRecord::RecordNotFound
      render(json: { "title": "Invalid Child OID" }, status: 400) && (return false)
    end
    return unless check_child_visibility(child_object)
    SaveOriginalToS3Job.perform_later(child_object.oid)
    render(json: { "title": "Child object staged for download." }, status: 200)
  end


  def check_child_visibility(child_object)
    if child_object.parent_object.visibility == "Private" || child_object.parent_object.visibility == "Redirect"
      render(json: { "title": "Child Object is restricted." }, status: 403) && (return false)
    end
    true
  end

  private

    def download_original_params
      params.require(:download_original).permit(:oid)
    end
end