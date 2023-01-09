# frozen_string_literal: true

class Api::DownloadController < ApplicationController

  def stage
    request = params
    begin
      child_object = ChildObject.find(request['oid'].to_i)
    rescue ActiveRecord::RecordNotFound
      render(json: { "title": "Invalid Child OID" }, status: 400) && (return false)
    end
    return unless check_child_visibility(child_object)
    SaveOriginalToS3Job.perform(child_object.oid)
  end


  def check_child_visibility(child_object)
    if child_object.parent_object.visibility != "Yale Community Only" || child_object.parent_object.visibility != "Public"
      render(json: { "title": "Child Object is restricted." }, status: 403) && (return false)
    end
    true
  end
end