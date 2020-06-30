# frozen_string_literal: true
# A parent object is the unit of discovery (what is represented as a single record in Blacklight).
# It is synonymous with a parent oid in Ladybird.

class ParentObject < ApplicationRecord
  has_many :dependent_objects
  self.primary_key = 'oid'
  # t.string "oid" - Unique identifier for a ParentObject, currently from Ladybird, eventually will be minted by this application
  # t.index ["oid"], name: "index_parent_objects_on_oid", unique: true
  # t.string "bib" - Identifier from Voyager, the integrated library system ("ils"). Short for Bibliographic record.
  # t.string "holding" - Identifier from Voyager
  # t.string "item" - Identifier from Voyager
  # t.string "barcode"
  # t.string "aspace_uri" - Identifier from ArchiveSpace
  # t.datetime "created_at", precision: 6, null: false
  # t.datetime "updated_at", precision: 6, null: false
  # t.datetime "last_id_update" - Last time the crosswalk between all the ids was updated based on the Ladybird data
  # t.datetime "last_ladybird_update" - Last time the Ladybird record was updated from MetadataCloud
  # t.datetime "last_voyager_update" - Last time the Voyager record was updated from MetadataCloud
  # t.datetime "last_aspace_update" - Last time the ArchiveSpace record was updated from MetadataCloud
end
