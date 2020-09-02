# frozen_string_literal: true

class ChildObject < ApplicationRecord
  belongs_to :parent_object, foreign_key: 'parent_object_oid', class_name: "ParentObject"
  self.primary_key = 'oid'

  def remote_ptiff_exists?
    S3Service.image_exists?(remote_ptiff_path)
  end

  def remote_ptiff_path
    PyramidalTiffFactory.remote_ptiff_path(oid)
  end

  def access_master_path
    PyramidalTiffFactory.access_master_path(oid)
  end

  def convert_to_ptiff
    conversion_information = PyramidalTiffFactory.generate_ptiff_from(self)
    return unless conversion_information
    self.width = conversion_information[:width]
    self.height = conversion_information[:height]
    save
  end
end
