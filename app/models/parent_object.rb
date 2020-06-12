# frozen_string_literal: true
# A parent object is the unit of discovery (what is represented as a single record in Blacklight).
# It is synonymous with a parent oid in Ladybird.

class ParentObject < ApplicationRecord
  # t.string "oid" - Unique identifier for a ParentObject, currently from Ladybird, eventually will be minted by this application
  # t.index ["oid"], name: "index_parent_objects_on_oid", unique: true
  # t.string "bib_id" - Identifier from Voyager, the integrated library system ("ils"). Short for Bibliographic record.
  # t.string "holding_id" - Identifier from Voyager
  # t.string "item_id" - Identifier from Voyager
  # t.string "barcode"
  # t.string "aspace_uri" - Identifier from ArchiveSpace
  # t.datetime "last_mc_update" - Last time the record was updated from MetadataCloud
  # t.datetime "created_at", precision: 6, null: false
  # t.datetime "updated_at", precision: 6, null: false
  # t.datetime "last_id_upate" - Last time the crosswalk between all the ids was updated based on the Ladybird data
end
