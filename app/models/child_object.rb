# frozen_string_literal: true

class ChildObject < ApplicationRecord
  belongs_to :parent_object, foreign_key: 'parent_object_oid', class_name: "ParentObject"
  self.primary_key = 'oid'

  def remote_ptiff_exists?
    S3Service.s3_exists?(remote_ptiff_path)
  end

  def access_master_path
    return @access_master_path if @access_master_path
    image_mount = ENV['ACCESS_MASTER_MOUNT'] || "data"
    pairtree_path = Partridge::Pairtree.oid_to_pairtree(oid)
    @access_master_path = File.join(image_mount, pairtree_path, "#{oid}.tif")
  end

  def remote_access_master_path
    return @remote_access_master_path if @remote_access_master_path
    image_bucket = "originals"
    pairtree_path = Partridge::Pairtree.oid_to_pairtree(oid)
    @remote_access_master_path = File.join(image_bucket, pairtree_path, "#{oid}.tif")
  end

  def remote_ptiff_path
    return @remote_ptiff_path if @remote_ptiff_path
    pairtree_path = Partridge::Pairtree.oid_to_pairtree(oid)
    @remote_ptiff_path = File.join("ptiffs", pairtree_path, File.basename(access_master_path))
  end

  def pyramidal_tiff
    @pyramidal_tiff ||= PyramidalTiff.new(self)
  end

  def thumbnail_url
    "#{IiifPresentation.new(parent_object).image_url(oid)}/full/200,/0/default.jpg"
  end

  def convert_to_ptiff
    if pyramidal_tiff.valid?
      self.width = pyramidal_tiff.conversion_information[:width]
      self.height = pyramidal_tiff.conversion_information[:height]
      self.ptiff_conversion_at = Time.current
      pyramidal_tiff.conversion_information
    else
      parent_object.processing_failure("Child Object #{oid} failed to convert PTIFF due to #{pyramidal_tiff.errors.full_messages.join("\n")}")
    end
  end

  def convert_to_ptiff!
    convert_to_ptiff && save!
  end
end
