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
end
