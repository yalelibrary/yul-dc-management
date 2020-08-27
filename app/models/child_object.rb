# frozen_string_literal: true

class ChildObject < ApplicationRecord
  belongs_to :parent_object, foreign_key: 'parent_object_oid', class_name: "ParentObject"
  self.primary_key = 'child_oid'

  def has_ptiff?
    # TODO: put a real method here
    false
  end

  def access_master_path
    PyramidalTiffFactory.access_master_path(child_oid)
  end
end
