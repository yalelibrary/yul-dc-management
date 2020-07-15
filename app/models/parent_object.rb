# frozen_string_literal: true
# A parent object is the unit of discovery (what is represented as a single record in Blacklight).
# It is synonymous with a parent oid in Ladybird.

class ParentObject < ApplicationRecord
  has_many :dependent_objects
  belongs_to :authoritative_metadata_source, class_name: "MetadataSource"

  self.primary_key = 'oid'

  before_create :default_fetch, unless: proc { ladybird_json.present? }

  # Fetches the record from the authoritative_metadata_source
  def default_fetch
    case authoritative_metadata_source.metadata_cloud_name
    when "ladybird"
      self.ladybird_json = MetadataSource.find_by(metadata_cloud_name: "ladybird").fetch_record(self)
    when "ils"
      self.ladybird_json = MetadataSource.find_by(metadata_cloud_name: "ladybird").fetch_record(self)
      self.voyager_json = MetadataSource.find_by(metadata_cloud_name: "ils").fetch_record(self)
    when "aspace"
      self.ladybird_json = MetadataSource.find_by(metadata_cloud_name: "ladybird").fetch_record(self)
      self.aspace_json = MetadataSource.find_by(metadata_cloud_name: "aspace").fetch_record(self)
    end
  end

  def complete_fetch
    self.ladybird_json = MetadataSource.find_by(metadata_cloud_name: "ladybird").fetch_record(self)
    self.voyager_json = MetadataSource.find_by(metadata_cloud_name: "ils").fetch_record(self)
    return unless ladybird_json["archiveSpaceUri"]
    self.aspace_json = MetadataSource.find_by(metadata_cloud_name: "aspace").fetch_record(self)
  end

  # Takes a JSON record from the MetadataCloud and saves the Ladybird-specific info to the DB
  def ladybird_json=(lb_record)
    super(lb_record)
    self.bib = lb_record["orbisRecord"]
    self.barcode = lb_record["orbisBarcode"]
    self.aspace_uri = lb_record["archiveSpaceUri"]
    self.visibility = lb_record["itemPermission"]
    self.last_ladybird_update = DateTime.current
  end

  def voyager_json=(v_record)
    super(v_record)
    self.holding = v_record["holdingId"]
    self.item = v_record["itemId"]
    self.last_id_update = DateTime.current
    self.last_voyager_update = DateTime.current
  end

  def aspace_json=(a_record)
    super(a_record)
    self.last_aspace_update = DateTime.current
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
end
