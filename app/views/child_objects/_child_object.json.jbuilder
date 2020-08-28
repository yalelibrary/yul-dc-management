# frozen_string_literal: true

json.extract! child_object, :id, :oid, :caption, :width, :height, :order, :parent_object_oid, :created_at, :updated_at
json.url child_object_url(child_object, format: :json)
