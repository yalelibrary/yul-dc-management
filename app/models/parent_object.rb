# frozen_string_literal: true
# A parent object is the unit of discovery (what is represented as a single record in Blacklight).
# It is synonymous with a parent oid in Ladybird.

class ParentObject < ApplicationRecord # rubocop:disable Metrics/ClassLength
  include JsonFile
  include SolrIndexable
  include Statable
  include PdfRepresentable
  has_many :dependent_objects
  has_many :child_objects, primary_key: 'oid', foreign_key: 'parent_object_oid', dependent: :destroy
  has_many :batch_connections, as: :connectable
  has_many :batch_processes, through: :batch_connections
  belongs_to :authoritative_metadata_source, class_name: "MetadataSource"
  attr_accessor :metadata_update
  attr_accessor :current_batch_process
  attr_accessor :current_batch_connection
  self.primary_key = 'oid'
  after_save :setup_metadata_job
  after_update :solr_index_job # we index from the fetch job on create
  after_destroy :solr_delete
  after_destroy :note_deletion
  paginates_per 50

  def self.visibilities
    ['Private', 'Public', 'Yale Community Only']
  end

  # Options from iiif presentation api 2.1 - see https://iiif.io/api/presentation/2.1/#viewingdirection
  def self.viewing_directions
    [nil, "left-to-right", "right-to-left", "top-to-bottom", "bottom-to-top"]
  end

  # Options from iiif presentation api 2.1 - see https://iiif.io/api/presentation/2.1/#viewinghint
  def self.viewing_hints
    [nil, "individuals", "paged", "continuous"]
  end

  validates :visibility, inclusion: { in: visibilities,
                                      message: "%{value} is not a valid value" }

  def initialize(attributes = nil)
    super
    self.use_ladybird = true
  end

  def start_states
    ['processing-queued']
  end

  def finished_states
    ['solr-indexed', 'pdf-generated']
  end

  # Note - the upsert_all method skips ActiveRecord callbacks, and is entirely
  # database driven. This also makes object creation much faster.
  def create_child_records
    if from_mets == true
      ChildObject.upsert_all(array_of_child_hashes_from_mets)
    else
      return unless ladybird_json
      return self.child_object_count = 0 if ladybird_json["children"].empty?
      ChildObject.upsert_all(array_of_child_hashes)
    end
    self.child_object_count = child_objects.size
  end

  def array_of_child_hashes_from_mets
    return unless current_batch_process&.mets_doc
    current_batch_process.mets_doc.combined.map { |child_hash| child_hash.select { |k| k != :thumbnail_flag } }
  end

  def array_of_child_hashes
    return unless ladybird_json
    ladybird_json["children"].map.with_index(1) do |child_record, index|
      {
        oid: child_record["oid"],
        # Ladybird has only one field for both order label (7v, etc.), and descriptive captions ("Mozart at the Keyboard")
        # For the first iteration we will map this field to label
        label: child_record["caption"],
        order: index,
        parent_object_oid: oid
      }
    end
  end

  # Fetches the record from the authoritative_metadata_source
  def default_fetch(_current_batch_process = current_batch_process, _current_batch_connection = current_batch_connection)
    fetch_results = case authoritative_metadata_source&.metadata_cloud_name
                    when "ladybird"
                      self.ladybird_json = MetadataSource.find_by(metadata_cloud_name: "ladybird").fetch_record(self)
                    when "ils"
                      self.voyager_json = MetadataSource.find_by(metadata_cloud_name: "ils").fetch_record(self)
                    when "aspace"
                      self.aspace_json = MetadataSource.find_by(metadata_cloud_name: "aspace").fetch_record(self)
                    end
    processing_event("Metadata has been fetched", "metadata-fetched") if fetch_results
    fetch_results
  end

  def processing_event(message, status = 'info', _current_batch_process = current_batch_process, current_batch_connection = self.current_batch_connection)
    return "no batch connection" unless current_batch_connection
    IngestEvent.create!(
      status: status,
      reason: message,
      batch_connection: current_batch_connection
    )
    current_batch_connection&.save! unless current_batch_connection&.persisted?
    current_batch_connection&.update_status!
  end

  # Currently we run this job if the record is new and ladybird json wasn't passed in from create
  # OR if the authoritative metaadata source changes
  # OR if the metadata_update accessor is set
  def setup_metadata_job(current_batch_connection = self.current_batch_connection)
    if (created_at_previously_changed? && ladybird_json.blank?) ||
       previous_changes["authoritative_metadata_source_id"].present? ||
       metadata_update.present?
      current_batch_connection&.save! unless current_batch_connection&.persisted?
      SetupMetadataJob.perform_later(self, current_batch_process, current_batch_connection)
      processing_event("Processing has been queued", "processing-queued", current_batch_process, current_batch_connection)
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
    self.last_ladybird_update = DateTime.current
    return unless use_ladybird
    self.bib = lb_record["orbisBibId"]
    self.barcode = lb_record["orbisBarcode"]
    self.aspace_uri = lb_record["archiveSpaceUri"]
    self.visibility = lb_record["itemPermission"]
    self.rights_statement = lb_record["rights"]&.first
    self.use_ladybird = false
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
    "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/#{MetadataSource.metadata_cloud_version}/ladybird/oid/#{oid}?include-children=1"
  end

  def voyager_cloud_url
    # if we're working from a mets document, use the MetadataCloud call from the mets document
    return "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/#{MetadataSource.metadata_cloud_version}#{current_batch_process.mets_doc.metadata_source_path}" if from_mets
    raise StandardError, "Bib id required to build Voyager url" unless bib.present?
    identifier_block = if !barcode.present?
                         "/bib/#{bib}"
                       else
                         "/barcode/#{barcode}?bib=#{bib}"
                       end
    "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/#{MetadataSource.metadata_cloud_version}/ils#{identifier_block}"
  end

  def aspace_cloud_url
    # if we're working from a mets document, use the MetadataCloud call from the mets document
    return "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/#{MetadataSource.metadata_cloud_version}#{current_batch_process.mets_doc.metadata_source_path}" if from_mets
    raise StandardError, "ArchiveSpace uri required to build ArchiveSpace url" unless aspace_uri.present?
    "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/#{MetadataSource.metadata_cloud_version}/aspace#{aspace_uri}"
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

  def needs_a_manifest?
    ready_for_manifest? && generate_manifest
  end

  def ready_for_manifest?
    !child_objects.pluck(:width).include?(nil)
  end

  def representative_child
    @representative_child = (child_objects.find_by(oid: representative_child_oid) if representative_child_oid)
    @representative_child ||= child_objects.where(order: 1)&.first
  end

  def representative_thumbnail_url
    representative_child&.thumbnail_url
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

  def extract_container_information(json = authoritative_json)
    return nil unless json
    return json["containerGrouping"] unless json["containerGrouping"].nil? || json["containerGrouping"].empty?
    return [(json["box"] && (json['box']).to_s), (json["folder"] && (json['folder']).to_s)].join(", ") if json["box"] || json["folder"]
    json["volumeEnumeration"]
  end

  def dl_show_url
    base = ENV['BLACKLIGHT_BASE_URL'] || 'localhost:3000'
    "#{base}/catalog/#{oid}"
  end
end
