# frozen_string_literal: true

json.array! @child_objects, partial: "child_objects/child_object", as: :child_object
