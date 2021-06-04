# frozen_string_literal: true

json.extract! parent_object, :id, :oid, :bib, :holding, :item, :barcode, :aspace_uri, :last_ladybird_update,
              :last_voyager_update, :last_aspace_update, :visibility, :last_id_update, :created_at, :updated_at, :extent_of_digitization, :digitization_note
json.url parent_object_url(parent_object, format: :json)
