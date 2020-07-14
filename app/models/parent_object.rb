# frozen_string_literal: true
# A parent object is the unit of discovery (what is represented as a single record in Blacklight).
# It is synonymous with a parent oid in Ladybird.

class ParentObject < ApplicationRecord
  has_many :dependent_objects
  self.primary_key = 'oid'
  before_create :complete_fetch

  def complete_fetch
    self.ladybird_json = MetadataSource.find_by(metadata_cloud_name: "ladybird").fetch_record(self)
    self.voyager_json = MetadataSource.find_by(metadata_cloud_name: "ils").fetch_record(self)
    return unless ladybird_json["archiveSpaceUri"]
    self.aspace_json = MetadataSource.find_by(metadata_cloud_name: "aspace").fetch_record(self)
  end

  # Takes a JSON record from the MetadataCloud and saves the Ladybird-specific info to the DB
  def ladybird_json=(lb_record)
    super(lb_record)
    bib = lb_record["orbisRecord"]
    barcode = lb_record["orbisBarcode"]
    aspace_uri = lb_record["archiveSpaceUri"]
    visibility = lb_record["itemPermission"]
    last_ladybird_update = DateTime.current
  end

  def voyager_json=(v_record)
    super(v_record)
    holding = v_record["holdingId"]
    item = v_record["itemId"]
    last_id_update = DateTime.current
    last_voyager_update = DateTime.current
  end

  def aspace_json=(a_record)
    super(a_record)
    last_aspace_update = DateTime.current
  end

  def ladybird_cloud_url
    "https://metadata-api-test.library.yale.edu/metadatacloud/api/ladybird/oid/#{oid}"
  end

  def voyager_cloud_url
    return nil unless ladybird_json.present?
    identifier_block = if ladybird_json["orbisBarcode"].nil?
                         "/bib/#{ladybird_json['orbisRecord']}"
                       else
                         "/barcode/#{ladybird_json['orbisBarcode']}?bib=#{ladybird_json['orbisRecord']}"
                       end
    "https://metadata-api-test.library.yale.edu/metadatacloud/api/ils#{identifier_block}"
  end

  def aspace_cloud_url
    return nil unless ladybird_json.present?
    "https://metadata-api-test.library.yale.edu/metadatacloud/api/aspace#{ladybird_json['archiveSpaceUri']}"
  end

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
