# frozen_string_literal: true
# A parent object is the unit of discovery (what is represented as a single record in Blacklight).
# It is synonymous with a parent oid in Ladybird.

class ParentObject < ApplicationRecord
  include JsonFile
  include SolrIndexable
  has_many :dependent_objects
  has_many :child_objects, primary_key: 'oid', foreign_key: 'parent_object_oid', dependent: :destroy
  belongs_to :authoritative_metadata_source, class_name: "MetadataSource"

  self.primary_key = 'oid'
  before_validation :default_fetch, on: :create, unless: proc { ladybird_json.present? }
  after_save :solr_index
  before_save :create_child_records

  def create_child_records
    return unless ladybird_json
    ladybird_json["children"].map do |child_record|
      next if self.child_object_ids.include?(child_record["oid"])
      self.child_objects.build(
        child_oid: child_record["oid"],
        caption: child_record["caption"],
        width: child_record["width"],
        height: child_record["height"]
        )
    end
    self.child_object_count = self.child_objects.size
  end

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

  def authoritative_json
    json_for(authoritative_metadata_source.metadata_cloud_name)
  end

  def json_for(source_name)
    case source_name
    when "ladybird"
      ladybird_json
    when "ils"
      voyager_json
    when "aspace"
      aspace_json
    else
      raise StandardError, "Unexpected metadata cloud name: #{authoritative_metadata_source.metadata_cloud_name}"
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
    return lb_record if lb_record.blank?
    self.bib = lb_record["orbisBibId"] || lb_record["orbisRecord"]
    self.barcode = lb_record["orbisBarcode"]
    self.aspace_uri = lb_record["archiveSpaceUri"]
    self.visibility = lb_record["itemPermission"]
    self.last_ladybird_update = DateTime.current
  end

  def voyager_json=(v_record)
    super(v_record)
    return v_record if v_record.blank?
    self.holding = v_record["holdingId"]
    self.item = v_record["itemId"]
    self.last_id_update = DateTime.current
    self.last_voyager_update = DateTime.current
  end

  def aspace_json=(a_record)
    super(a_record)
    self.last_aspace_update = DateTime.current if a_record.present?
  end

  def ladybird_cloud_url
    "https://#{MetadataCloudService.metadata_cloud_host}/metadatacloud/api/ladybird/oid/#{oid}?include-children=1"
  end

  def voyager_cloud_url
    return nil unless ladybird_json.present?
    orbis_bib = ladybird_json['orbisRecord'] || ladybird_json['orbisBibId']
    identifier_block = if ladybird_json["orbisBarcode"].nil?
                         "/bib/#{orbis_bib}"
                       else
                         "/barcode/#{ladybird_json['orbisBarcode']}?bib=#{orbis_bib}"
                       end
    "https://#{MetadataCloudService.metadata_cloud_host}/metadatacloud/api/ils#{identifier_block}"
  end

  def aspace_cloud_url
    return nil unless ladybird_json.present?
    "https://#{MetadataCloudService.metadata_cloud_host}/metadatacloud/api/aspace#{ladybird_json['archiveSpaceUri']}"
  end

  def source_name=(metadata_source)
    self.authoritative_metadata_source = MetadataSource.find_by(metadata_cloud_name: metadata_source)
  end

  def source_name
    authoritative_metadata_source&.metadata_cloud_name
  end
end
