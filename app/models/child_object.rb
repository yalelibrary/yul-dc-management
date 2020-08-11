# frozen_string_literal: true

class ChildObject < ApplicationRecord
  belongs_to :parent_object, class_name: "ParentObject"
end
