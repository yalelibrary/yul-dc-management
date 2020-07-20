# frozen_string_literal: true

json.array! @parent_objects, partial: "parent_objects/parent_object", as: :parent_object
