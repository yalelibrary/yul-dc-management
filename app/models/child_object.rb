# frozen_string_literal: true

class ChildObject < ApplicationRecord
  belongs_to :parent_object, foreign_key: 'parent_object_oid', class_name: "ParentObject"
  self.primary_key = 'oid'

  def remote_ptiff_exists?
    S3Service.s3_exists?(remote_ptiff_path)
  end

  def remote_ptiff_path
    PyramidalTiffFactory.remote_ptiff_path(oid)
  end

  def access_master_path
    PyramidalTiffFactory.access_master_path(oid)
  end

  def remote_access_master_path
    PyramidalTiffFactory.remote_access_master_path(oid)
  end

  def thumbnail_url
    "#{IiifPresentation.image_url(oid)}/full/200,/0/default.jpg"
  end

  def convert_to_ptiff
    conversion_information = PyramidalTiffFactory.generate_ptiff_from(self)
    return unless conversion_information
    self.width = conversion_information[:width]
    self.height = conversion_information[:height]
    self.ptiff_conversion_at = Time.current
    conversion_information
  end
end
