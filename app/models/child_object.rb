class ChildObject < ApplicationRecord
  belongs_to :parent_object, class_name: "ParentObject"
end
