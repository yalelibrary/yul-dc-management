# frozen_string_literal: true
# A parent object is the unit of discovery (what is represented as a single record in Blacklight).
# It is synonymous with a parent oid in Ladybird.

class ParentObject < ApplicationRecord # rubocop:disable Metrics/ClassLength
  include JsonFile
  include SolrIndexable
  has_many :dependent_objects
  has_many :child_objects, primary_key: 'oid', foreign_key: 'parent_object_oid', dependent: :destroy
  has_many :batch_connections, as: :connection
  has_many :batch_processes, through: :batch_connections
  belongs_to :authoritative_metadata_source, class_name: "MetadataSource"
  attr_accessor :metadata_update
  attr_accessor :current_batch_process
  self.primary_key = 'oid'
  after_save :setup_metadata_job
  after_update :solr_index_job # we index from the fetch job on create
  after_destroy :solr_delete
  paginates_per 50

  def self.visibilities
    ['Private', 'Public', 'Yale Community Only']
  end

  validates :visibility, inclusion: { in: visibilities,
                                      message: "%{value} is not a valid value" }

  def create_child_records
    return unless ladybird_json
    ladybird_json["children"].map.with_index(1) do |child_record, index|
      next if child_object_ids.include?(child_record["oid"])
      child_objects.build(
        oid: child_record["oid"],
        # Ladybird has only one field for both order label (7v, etc.), and descriptive captions ("Mozart at the Keyboard")
        # For the first iteration we will map this field to label
        label: child_record["caption"],
        order: index
      )
    end
    self.child_object_count = child_objects.size
  end

  # Fetches the record from the authoritative_metadata_source
  def default_fetch
    case authoritative_metadata_source&.metadata_cloud_name
    when "ladybird"
      self.ladybird_json = MetadataSource.find_by(metadata_cloud_name: "ladybird").fetch_record(self)
    when "ils"
      self.ladybird_json = MetadataSource.find_by(metadata_cloud_name: "ladybird").fetch_record(self)
      self.voyager_json = MetadataSource.find_by(metadata_cloud_name: "ils").fetch_record(self)
    when "aspace"
      self.ladybird_json = MetadataSource.find_by(metadata_cloud_name: "ladybird").fetch_record(self)
      self.aspace_json = MetadataSource.find_by(metadata_cloud_name: "aspace").fetch_record(self)
    end
    processing_event("Metadata has been fetched", "successful")
  end

  def processing_event(message, status = 'info')
    IngestNotification.with(parent_object: self, status: status, reason: message, batch_process: current_batch_process).deliver_all
  end

  # Currently we run this job if the record is new and ladybird json wasn't passed in from create
  # OR if the authoritative metaadata source changes
  # OR if the metadata_update accessor is set
  def setup_metadata_job
    if (created_at_previously_changed? && ladybird_json.blank?) ||
       previous_changes["authoritative_metadata_source_id"].present? ||
       metadata_update.present?
      processing_event("Processing has been queued", "successful")
      SetupMetadataJob.perform_later(self, current_batch_process)
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
    "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/ladybird/oid/#{oid}?include-children=1"
  end

  def voyager_cloud_url
    return nil unless ladybird_json.present?
    orbis_bib = ladybird_json['orbisRecord'] || ladybird_json['orbisBibId']
    identifier_block = if ladybird_json["orbisBarcode"].nil?
                         "/bib/#{orbis_bib}"
                       else
                         "/barcode/#{ladybird_json['orbisBarcode']}?bib=#{orbis_bib}"
                       end
    "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/ils#{identifier_block}"
  end

  def aspace_cloud_url
    return nil unless ladybird_json.present?
    "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/aspace#{ladybird_json['archiveSpaceUri']}"
  end

  def source_name=(metadata_source)
    self.authoritative_metadata_source = MetadataSource.find_by(metadata_cloud_name: metadata_source)
  end

  def source_name
    authoritative_metadata_source&.metadata_cloud_name
  end

  def iiif_presentation
    @iiif_presentation ||= IiifPresentation.new(self)
  end

  def iiif_manifest
    return @iiif_manifest if @iiif_manifest
    @iiif_manifest = @iiif_presentation.manifest if iiif_presentation.valid?
  end

  def manifest_completed?
    ready_for_manifest? && iiif_presentation.valid? && S3Service.s3_exists?(iiif_presentation.manifest_path, ENV['SAMPLE_BUCKET'])
  end

  def ready_for_manifest?
    !child_objects.pluck(:ptiff_conversion_at).include?(nil)
  end

  def representative_thumbnail
    oid = child_objects.where(order: 1)&.first&.oid
    "#{ENV['IIIF_IMAGE_BASE_URL']}/2/#{oid}/full/!200,200/0/default.jpg"
  end

  def child_captions
    child_objects.map(&:caption).compact
  end

  def child_labels
    child_objects.map(&:label).compact
  end

  def child_oids
    child_objects.map(&:oid)
  end
end
