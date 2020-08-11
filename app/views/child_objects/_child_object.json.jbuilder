# frozen_string_literal: true

json.extract! child_object, :id, :child_oid, :caption, :width, :height, :order, :parent_object_id, :created_at, :updated_at
json.url child_object_url(child_object, format: :json)
