# frozen_string_literal: true

class BatchProcess < ApplicationRecord # rubocop:disable Metrics/ClassLength
  include CsvExportable
  include Reassociatable
  include Statable
  attr_reader :file
  after_create :determine_background_jobs
  before_create :mets_oid
  validate :validate_import
  belongs_to :user, class_name: "User"
  has_many :batch_connections
  has_many :parent_objects, through: :batch_connections, source_type: "ParentObject", source: :connectable
  has_many :child_objects, through: :batch_connections, source_type: "ChildObject", source: :connectable

  def self.batch_actions
    ['create parent objects', 'export child oids', 'reassociate child oids', 'recreate child oid ptiffs']
  end

  def batch_processing_event(message, status = 'info')
    current_batch_connection = batch_connections.find_or_create_by!(connectable: self)
    IngestEvent.create!(
      status: status,
      reason: message,
      batch_connection: current_batch_connection
    )
  end

  def batch_ingest_events
    current_batch_connection = batch_connections.find_or_create_by!(connectable: self)
    IngestEvent.where(batch_connection: current_batch_connection)
  end

  def batch_ingest_events_count
    current_batch_connection = batch_connections.find_or_create_by!(connectable: self)
    IngestEvent.where(batch_connection: current_batch_connection).count
  end

  def validate_import
    return if file.blank?
    if File.extname(file) == '.csv'
      errors.add(:file, 'must be a csv') if CSV.read(file).blank?
    elsif File.extname(file) == '.xml'
      return errors.add(:file, 'must be a valid METs file') unless mets_doc.valid_mets?
    else
      return errors.add(:file, 'not a valid file type. Must be a CSV or XML.')
    end
  end

  def file=(value)
    @file = value
    self[:file_name] = file.original_filename
    if File.extname(file) == '.csv'
      # Remove BOM if present
      self[:csv] = CSV.open(value, 'rb:bom|utf-8', headers: true, return_headers: true).read
    elsif File.extname(file) == '.xml'
      self[:mets_xml] = value.read
    end
  end

  def parsed_csv
    @parsed_csv ||= CSV.parse(csv, headers: true, encoding: "utf-8") if csv.present?
  end

  def mets_doc
    @mets_doc ||= MetsDocument.new(mets_xml) if mets_xml.present?
  end

  def mets_oid
    self[:oid] = mets_doc&.oid&.to_i unless self[:oid]
  end

  def oids
    return @oids ||= parsed_csv.entries.map { |r| r['oid'] } unless csv.nil?
    @oids ||= [oid]
  end

  def created_file_name
    return nil unless file_name
    "#{file_name.delete_suffix('.csv')}_bp_#{id}.csv"
  end

  def create_parent_objects_from_oids(oids, metadata_sources)
    oids.zip(metadata_sources).each do |oid, metadata_source|
      fresh = false
      po = ParentObject.where(oid: oid).first_or_create do |parent_object|
        # Only runs on newly created parent objects
        setup_for_background_jobs(parent_object, metadata_source)
        fresh = true
      end
      next if fresh
      po.metadata_update = true
      setup_for_background_jobs(po, metadata_source)
      po.save!
    end
  end

  def setup_for_background_jobs(object, metadata_source)
    object.authoritative_metadata_source = MetadataSource.find_by(metadata_cloud_name: (metadata_source.presence || 'ladybird')) if object.class == ParentObject
    object.current_batch_process = self
    object.current_batch_connection = batch_connections.build(connectable: object)
    object.current_batch_connection.save! if object.class == ChildObject
  end

  def refresh_metadata_cloud_csv
    metadata_sources = parsed_csv.entries.map { |r| r['Source'] }
    create_parent_objects_from_oids(oids, metadata_sources)
  end

  def recreate_child_oid_ptiffs
    parents = Set[]
    oids.each_with_index do |oid, index|
      child_object = ChildObject.find_by_oid(oid.to_i)
      unless child_object
        batch_processing_event("Skipping row [#{index}] with unknown Child: #{oid}", 'Skipped Row')
        next
      end
      next unless child_object
      parent_object = child_object.parent_object
      unless parents.include? parent_object.oid
        attach_item(parent_object)
        parent_object.processing_event("Connection to batch created", "parent-connection-created")
        parents.add parent_object.oid
      end
      GeneratePtiffJob.perform_later(child_object, self)
      attach_item(child_object)
      child_object.processing_event("Ptiff Queued", "ptiff-queued")
    end
  end

  def attach_item(connectable)
    connectable.current_batch_process = self
    connectable.current_batch_connection = batch_connections.find_or_create_by(connectable: connectable)
    connectable.current_batch_connection.save!
  end

  def refresh_metadata_cloud_mets
    fresh = false
    metadata_source = mets_doc.metadata_source
    po = ParentObject.where(oid: oid).first_or_create do |parent_object|
      # Only runs on newly created parent objects
      fresh = true
      set_values_from_mets(parent_object, metadata_source)
    end
    return if fresh
    po.metadata_update = true
    po.last_mets_update = Time.current
    setup_for_background_jobs(po, metadata_source)
    po.save!
  end

  def set_values_from_mets(parent_object, metadata_source)
    parent_object.bib = mets_doc.bib
    parent_object.barcode = mets_doc.barcode
    parent_object.holding = mets_doc.holding
    parent_object.item = mets_doc.item
    parent_object.visibility = mets_doc.visibility
    parent_object.rights_statement = mets_doc.rights_statement
    parent_object.viewing_direction = mets_doc.viewing_direction
    parent_object.display_layout = mets_doc.viewing_hint
    parent_object.aspace_uri = mets_doc.aspace_uri if mets_doc.valid_aspace?
    setup_for_background_jobs(parent_object, metadata_source)
    parent_object.from_mets = true
    parent_object.last_mets_update = Time.current
    parent_object.representative_child_oid = mets_doc.thumbnail_image
  end

  def determine_background_jobs
    if csv.present?
      case batch_action
      when 'create parent objects'
        RefreshMetadataCloudCsvJob.perform_later(self)
      when 'export child oids'
        CreateChildOidCsvJob.perform_later(self)
      when 'reassociate child oids'
        ReassociateChildOidsJob.perform_later(self)
      when 'recreate child oid ptiffs'
        RecreateChildOidPtiffsJob.perform_later(self)
      end
    elsif mets_xml.present?
      refresh_metadata_cloud_mets
    end
  end

  def batch_status
    current_status = status_hash
    if single_status(current_status)
      single_status(current_status)
    elsif current_status[:failed] != 0
      "#{current_status[:failed]} out of #{current_status[:total].to_i} parent objects have a failure."
    elsif current_status[:in_progress] != 0
      "#{current_status[:in_progress]} out of #{current_status[:total].to_i} parent objects are in progress."
    else
      "Batch status unknown"
    end
  end

  def single_status(current_status)
    if current_status[:in_progress] / current_status[:total] == 1
      "Batch in progress - no failures"
    elsif current_status[:complete] / current_status[:total] == 1
      "Batch complete"
    elsif current_status[:failed] / current_status[:total] == 1
      "Batch failed"
    end
  end

  def connected_statuses
    @connected_statuses ||= batch_connections.where(connectable_type: "ParentObject").map(&:status)
  end

  def status_hash
    @status_hash ||= {
      complete: connected_statuses.count("Complete"),
      in_progress: connected_statuses.count("In progress - no failures"),
      failed: connected_statuses.count("Failed"),
      unknown: connected_statuses.count("Unknown"),
      total: connected_statuses.count.to_f
    }
  end

  def are_all_children_complete?(parent_object)
    child_objects.where(parent_object: parent_object).all? do |co|
      co.status_for_batch_process(self) == 'Complete'
    end
  end
end
