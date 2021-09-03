# frozen_string_literal: true
# A parent object is the unit of discovery (what is represented as a single record in Blacklight).
# It is synonymous with a parent oid in Ladybird.

class ParentObject < ApplicationRecord # rubocop:disable Metrics/ClassLength
  has_paper_trail
  include JsonFile
  include SolrIndexable
  include Statable
  include PdfRepresentable
  include Delayable
  has_many :dependent_objects
  has_many :child_objects, -> { order('"order" ASC, oid ASC') }, primary_key: 'oid', foreign_key: 'parent_object_oid', dependent: :destroy
  has_many :batch_connections, as: :connectable
  has_many :batch_processes, through: :batch_connections
  belongs_to :authoritative_metadata_source, class_name: "MetadataSource"
  belongs_to :admin_set
  attr_accessor :metadata_update
  attr_accessor :current_batch_process
  attr_accessor :current_batch_connection
  self.primary_key = 'oid'
  after_save :setup_metadata_job
  after_update :solr_index_job # we index from the fetch job on create
  after_destroy :solr_delete
  after_destroy :note_deletion
  after_destroy :delayed_jobs_deletion
  after_destroy :pdf_deletion
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

  def self.extent_of_digitizations
    [nil, "Completely digitized", "Partially digitized"]
  end

  validates :visibility, inclusion: { in: visibilities, allow_nil: true,
                                      message: "%{value} is not a valid value" }

  def initialize(attributes = nil)
    super
    self.use_ladybird = true
  end

  def from_upstream_for_the_first_time?
    from_ladybird_for_the_first_time? || from_mets_for_the_first_time?
  end

  def self.cannot_reindex
    return true if Delayable.solr_reindex_jobs.count.positive?
  end

  # Returns true if last_ladybird_update has changed from nil to some value, indicating initial ladybird fetch
  def from_ladybird_for_the_first_time?
    return true if changes["last_ladybird_update"] &&
                   !changes["last_ladybird_update"][0] &&
                   changes["last_ladybird_update"][1]
    false
  end

  # Returns true if last_mets_update has changed from nil to some value,
  # indicating assigning values from the mets document
  def from_mets_for_the_first_time?
    return true if last_mets_update_before_last_save.nil? && !last_mets_update.nil?
    false
  end

  def start_states
    ['processing-queued']
  end

  def finished_states
    ['solr-indexed', 'pdf-generated', 'ptiffs-recreated', 'update-complete']
  end

  # Note - the upsert_all method skips ActiveRecord callbacks, and is entirely
  # database driven. This also makes object creation much faster.
  def create_child_records
    if from_mets
      upsert_child_objects(array_of_child_hashes_from_mets)
      upsert_preservica_ingest_child_objects(array_preservica_hashes_from_mets)

    else
      return unless ladybird_json
      return self.child_object_count = 0 if ladybird_json["children"].empty?
      upsert_child_objects(array_of_child_hashes)
    end
    self.child_object_count = child_objects.size
  end

  def upsert_child_objects(child_objects_hash)
    raise "One or more of the child objects exists, Unable to create children" if ChildObject.where(oid: child_objects_hash.map { |co| co[:oid] }).exists?

    ChildObject.insert_all(child_objects_hash)
  end

  def upsert_preservica_ingest_child_objects(preservica_ingest_hash)
    PreservicaIngest.insert_all(preservica_ingest_hash)
  end

  def array_of_child_hashes_from_mets
    return unless current_batch_process&.mets_doc
    current_batch_process.mets_doc.combined.map { |child_hash| child_hash.select { |k| k != :thumbnail_flag && k != :child_uuid && k != :physical_id && k != :logical_id } }
  end

  def array_preservica_hashes_from_mets
    return unless current_batch_process&.mets_doc
    current_batch_process.mets_doc.combined.map do |child_hash|
      { parent_oid: oid, preservica_id: current_batch_process.mets_doc.parent_uuid,
        batch_process_id: current_batch_process.id,
        ingest_time: Time.current, child_oid: child_hash[:oid],
        preservica_child_id: child_hash[:child_uuid] }
    end
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

  def assign_dependent_objects(json = authoritative_json)
    return unless json
    metadata_source = authoritative_metadata_source&.metadata_cloud_name
    dep_objs = []
    DependentObject.delete(dependent_objects)
    json["dependentUris"]&.each do |uri|
      dep_objs << DependentObject.create(
        dependent_uri: uri,
        metadata_source: metadata_source,
        parent_object_id: oid
      )
    end
    self.dependent_objects = dep_objs
  end

  # Fetches the record from the authoritative_metadata_source
  def default_fetch(_current_batch_process = current_batch_process, _current_batch_connection = current_batch_connection)
    fetch_results = case authoritative_metadata_source&.metadata_cloud_name
                    when "ladybird"
                      self.ladybird_json = MetadataSource.find_by(metadata_cloud_name: "ladybird").fetch_record(self)
                    when "ils"
                      self.ladybird_json = MetadataSource.find_by(metadata_cloud_name: "ladybird").fetch_record(self) unless bib.present?
                      self.voyager_json = MetadataSource.find_by(metadata_cloud_name: "ils").fetch_record(self)
                    when "aspace"
                      self.ladybird_json = MetadataSource.find_by(metadata_cloud_name: "ladybird").fetch_record(self) unless aspace_uri.present?
                      self.aspace_json = MetadataSource.find_by(metadata_cloud_name: "aspace").fetch_record(self)
                    end
    if fetch_results
      assign_dependent_objects
      assign_values
      processing_event("Metadata has been fetched", "metadata-fetched")
    end
    fetch_results
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
      processing_event("Processing has been queued", "processing-queued")
    end
  end

  def authoritative_json
    json_for(authoritative_metadata_source.metadata_cloud_name)
  end

  def assign_values
    self.call_number = authoritative_json["callNumber"].is_a?(Array) ? authoritative_json["callNumber"].first : authoritative_json["callNumber"]
    self.container_grouping = authoritative_json["containerGrouping"].is_a?(Array) ? authoritative_json["containerGrouping"].first : authoritative_json["containerGrouping"]
  end

  def metadata_cloud_url
    case source_name
    when "ladybird"
      ladybird_cloud_url
    when "ils"
      voyager_cloud_url
    when "aspace"
      aspace_cloud_url
    else
      raise StandardError, "Unexpected metadata cloud name: #{authoritative_metadata_source.metadata_cloud_name}"
    end
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

  # Takes a JSON record from the MetadataCloud and saves the Ladybird-specific info to the DB
  def ladybird_json=(lb_record)
    super(lb_record)
    return lb_record if lb_record.blank?
    self.last_ladybird_update = DateTime.current
    return unless use_ladybird
    self.bib = lb_record["orbisBibId"]
    self.barcode = lb_record["orbisBarcode"]
    self.aspace_uri = lb_record["archiveSpaceUri"]
    self.visibility = lb_record["itemPermission"].nil? ? "Private" : lb_record["itemPermission"]
    self.rights_statement = lb_record["rights"]&.first
    self.extent_of_digitization = normalize_extent_of_digitization
    self.use_ladybird = false
  end

  def normalize_extent_of_digitization
    extent_from_ladybird = ladybird_json&.[]("extentOfDigitization")&.first
    return unless extent_from_ladybird
    if extent_from_ladybird.start_with?("Comp")
      "Completely digitized"
    elsif extent_from_ladybird.start_with?("Part")
      "Partially digitized"
    end
  end

  def voyager_json=(v_record)
    super(v_record)
    return v_record if v_record.blank?
    self.holding = v_record["holdingId"] unless v_record["holdingId"].zero?
    self.item = v_record["itemId"] unless v_record["itemId"].zero?
    self.last_id_update = DateTime.current
    self.last_voyager_update = DateTime.current
  end

  def aspace_json=(a_record)
    super(a_record)
    self.last_aspace_update = DateTime.current if a_record.present?
    self.bib = a_record["orbisBibId"]
    self.barcode = a_record["orbisBarcode"]
  end

  def ladybird_cloud_url
    "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/#{MetadataSource.metadata_cloud_version}/ladybird/oid/#{oid}?include-children=1"
  end

  def voyager_cloud_url
    raise StandardError, "Bib id required to build Voyager url" unless bib.present?
    identifier_block = if barcode.present?
                         "/barcode/#{barcode}?bib=#{bib}"
                       elsif holding.present?
                         "/holding/#{holding}?bib=#{bib}"
                       elsif item.present?
                         "/item/#{item}?bib=#{bib}"
                       else
                         "/bib/#{bib}"
                       end
    "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/#{MetadataSource.metadata_cloud_version}/ils#{identifier_block}"
  end

  def aspace_cloud_url
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
    if ready_for_manifest? && generate_manifest
      updated_rows = ParentObject.default_scoped.where(oid: oid, generate_manifest: true).update_all(generate_manifest: false) # rubocop:disable Rails/SkipsModelValidations
      self.generate_manifest = false
      return updated_rows == 1
    end
    false
  end

  def ready_for_manifest?
    # returns false if any child objects have a width of nil
    !child_objects.pluck(:width).include?(nil)
  end

  def representative_child
    @representative_child = (child_objects.find_by(oid: representative_child_oid) if representative_child_oid)
    @representative_child ||= child_objects&.first
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
    base = ENV['BLACKLIGHT_BASE_URL'] || 'http://localhost:3000'
    "#{base}/catalog/#{oid}"
  end

  def batch_connections_for(batch_process)
    batch_connections.where(batch_process: batch_process)
  end

  def full_text?
    # Iterate over the child objects and check the bucket to see if the first children have a .txt file
    return false unless child_objects.any?
    child_objects.first.remote_ocr

    # This will iterate over all child objects to check if they have a .txt file in the ocr bucket
    # If any do not have a .txt file, the loop will exit and return false

    # child_objects.each do |object|
    #   return false unless object.remote_ocr
    # end
    # true
  end
end
