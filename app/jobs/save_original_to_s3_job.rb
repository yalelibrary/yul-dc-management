# frozen_string_literal: true

class SaveOriginalToS3Job < ApplicationJob
  queue_as :default

  def default_priority
    100
  end

  def perform(child_object_oid)
    # check parent visibility is either public or YCO
    child_object = ChildObject.find(child_object_oid)
    parent_object = child_object.parent_object
    if parent_object.visibility == "Private" || parent_object.visibility == "Redirect"
      raise "Not copying image from #{parent_object.oid}. Parent object must have Public or Yale Community Only visibility."
    end
    # check if file already exists on S3
    if S3Service.s3_exists?(remote_download_path(child_object_oid))
      raise "Not copying image. Child object #{child_object_oid} already exists on S3."
    end
    # copy original to downloads bucket
  end

  def remote_download_path(oid)
    "download/tiff/#{Partridge::Pairtree.oid_to_pairtree(oid)}/#{oid}.tif"
  end
end
