# frozen_string_literal: true

class BatchProcess < ApplicationRecord # rubocop:disable Metrics/ClassLength
  # CSV EXPORT CHILD OIDS:
  include CsvExportable
  # DELETE PARENT / CHILD OBJECTS:
  include Deletable
  # CHECK IMAGE INTEGRITY:
  include IntegrityCheckable
  # REASSOCIATE CHILD OIDS:
  include Reassociatable
  include Statable
  # UPDATE PARENT OBJECTS:
  include Updatable
  # CREATE PARENR OBJECTS:
  include CreateParentObject
  # SYNC FROM PRESERVICA
  include SyncFromPreservica
  # REFRESH METS
  include RefreshMet
  # UPDATE FULLTEXT
  include UpdateFulltextStatus
  # RECREATE CHILD OID PTIFFS:
  include RecreateChildPtiff
  attr_reader :file
  after_create :determine_background_jobs
  before_create :mets_oid
  validate :validate_import
  belongs_to :user, class_name: "User"
  has_many :batch_connections
  has_many :parent_objects, through: :batch_connections, source_type: "ParentObject", source: :connectable
  has_many :child_objects, through: :batch_connections, source_type: "ChildObject", source: :connectable

  CSV_MAXIMUM_ENTRIES = 10_000

  # SHARED BY ALL BATCH ACTIONS: ------------------------------------------------------------------- #

  # LISTS AVAILABLE BATCH ACTIONS
  # rubocop:disable Layout/LineLength
  def self.batch_actions
    ['create parent objects', 'update parent objects', 'update child objects caption and label', 'delete parent objects', 'delete child objects', 'export all parent objects by admin set', 'export parent metadata', 'export child oids', 'reassociate child oids', 'recreate child oid ptiffs', 'reindex all parents', 'update fulltext status', 'resync with preservica', 'activity stream updates']
  end
  # rubocop:enable Layout/LineLength

  # LOGS BATCH PROCESSING MESSAGES AND SETS STATUSES
  def batch_processing_event(message, status = 'info')
    current_batch_connection = batch_connections.find_or_create_by!(connectable: self)
    IngestEvent.create!(
      status: status,
      reason: message,
      batch_connection: current_batch_connection
    )
  end

  # PROVIDES ROUTE TO CSV TEMPLATE
  def self.csv_template(batch_action)
    File.read(Rails.root.join("public", "batch_processes", "templates", "#{batch_action.parameterize.underscore}.csv"))
  end

  # GETS LISTS OF INGEST EVENTS
  def batch_ingest_events
    current_batch_connection = batch_connections.find_or_create_by!(connectable: self)
    IngestEvent.where(batch_connection: current_batch_connection)
  end

  # GETS COUNT OF INGEST EVENTS
  def batch_ingest_events_count
    current_batch_connection = batch_connections.find_or_create_by!(connectable: self)
    IngestEvent.where(batch_connection: current_batch_connection).count
  end

  # CHECKS TO SEE IF THE FILE UPLOADED IS A VALID FILE TYPE (CSV or XML)
  def validate_import
    return if file.blank?
    if File.extname(file) == '.csv'
      errors.add(:file, 'must be a csv') if CSV.read(file).blank?
    elsif File.extname(file) == '.xml'
      begin
          mets_doc.valid_mets?
      rescue => error
        errors.add(:file, error)
        end
    else
      errors.add(:file, 'not a valid file type. Must be a CSV or XML.')
    end
  end

  # READS FILE
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

  # PARSES THE CSV
  def parsed_csv
    @parsed_csv ||= CSV.parse(csv, headers: true, encoding: "utf-8", skip_blanks: true) if csv.present?
  end

  # CHECKS TO SEE IF CSV ROWS EXCEEDS MAXIMUM ENTRIES
  def check_csv_size
    if parsed_csv.length > CSV_MAXIMUM_ENTRIES
      error = "CSV contains #{parsed_csv.length} entries, which is more than the maximum number of #{CSV_MAXIMUM_ENTRIES}.  The job was not started."
      batch_processing_event(error, 'error')
      return false
    end
    true
  end

  def check_csv_row_data
    if parsed_csv.empty?
      error = "Process failed. The CSV does not contain any data."
      batch_processing_event(error, 'error')
      return false
    end
    true
  end

  # CREATES METS DOCUMENT
  def mets_doc
    @mets_doc ||= MetsDocument.new(mets_xml) if mets_xml.present?
  end

  # GETS THE OIDS FROM METS DOCUMENT
  def mets_oid
    self[:oid] = mets_doc&.oid&.to_i unless self[:oid]
  end

  # GETS THE OIDS FROM PARSED CSV
  def oids
    return @oids ||= parsed_csv.entries.map { |r| r['oid'] } unless csv.nil?
    @oids ||= [oid]
  end

  # FETCHES USERS ABILITIES
  def current_ability
    @current_ability ||= Ability.new(user)
  end

  # ASSIGNS PARENT/CHILD OBJECT TO BATCH PROCESS FOR REASSOCIATE/RECREATE CHILD PTIFF
  # AND INTEGRITYCHECKABLE
  def attach_item(connectable)
    connectable.current_batch_process = self
    connectable.current_batch_connection = batch_connections.find_or_create_by(connectable: connectable)
    connectable.current_batch_connection.save!
  end

  # ASSIGN JOBS TO BATCH ACTIONS
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Metrics/MethodLength
  def determine_background_jobs
    if csv.present? && check_csv_size && check_csv_row_data
      case batch_action
      when 'create parent objects'
        CreateNewParentJob.perform_later(self)
      when 'delete parent objects'
        DeleteParentObjectsJob.perform_later(self)
      when 'delete child objects'
        DeleteChildObjectsJob.perform_later(self)
      when 'export parent metadata'
        ExportParentMetadataCsvJob.perform_later(self)
      when 'export all parent objects by admin set'
        CreateParentOidCsvJob.perform_later(self)
      when 'export all parents by source'
        ExportAllParentSourcesCsvJob.perform_later(self)
      when 'export child oids'
        CreateChildOidCsvJob.perform_later(self)
      when 'update parent objects'
        UpdateParentObjectsJob.perform_later(self)
      when 'update child objects caption and label'
        UpdateChildObjectsJob.perform_later(self)
      when 'reassociate child oids'
        ReassociateChildOidsJob.perform_later(self)
      when 'recreate child oid ptiffs'
        RecreateChildOidPtiffsJob.perform_later(self)
      when 'update fulltext status'
        UpdateFulltextStatusJob.perform_later(self)
      when 'resync with preservica'
        SyncFromPreservicaJob.perform_later(self)
      end
    elsif mets_xml.present?
      refresh_metadata_cloud_mets
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/PerceivedComplexity

  # SETS COMPLETE STATUS FOR RECREATE JOB
  def are_all_children_complete?(parent_object)
    child_objects.where(parent_object: parent_object).all? do |co|
      co.status_for_batch_process(self) == 'Complete'
    end
  end

  # ASSIGNS PARENT/CHILD OBJECT TO BATCH PROCESS FOR CREATE/DELETE/UPDATE
  def setup_for_background_jobs(object, metadata_source)
    object.authoritative_metadata_source = MetadataSource.find_by(metadata_cloud_name: (metadata_source.presence || 'ladybird')) if object.class == ParentObject
    object.current_batch_process = self
    object.current_batch_connection = batch_connections.find_by(connectable: object) || batch_connections.build(connectable: object)
    object.current_batch_connection.save!
  end

  # BATCH STATUSES: ------------------------------------------------------------------------------ #

  # SETS BATCH STATUS BASED ON CURRENT STATUS
  def batch_status
    current_status = status_hash
    if single_status(current_status)
      single_status(current_status)
    elsif current_status[:failed] != 0
      "#{current_status[:failed]} out of #{current_status[:total].to_i} parent objects have a failure."
    elsif current_status[:in_progress] != 0
      "#{current_status[:in_progress]} out of #{current_status[:total].to_i} parent objects are in progress."
    else
      "View Messages"
    end
  end

  # SETS BATCH SINGLE STATUS
  def single_status(current_status)
    if current_status[:in_progress] / current_status[:total] == 1
      "Batch in progress - no failures"
    elsif current_status[:complete] / current_status[:total] == 1
      "Batch complete"
    elsif current_status[:failed] / current_status[:total] == 1
      "Batch failed"
    end
  end

  # ADDS ADMIN SET KEYS TO BP TABLE
  def add_admin_set_to_bp(sets, object)
    if object.class == ChildObject
      sets << ', ' + object.parent_object.admin_set.key
    elsif object.class == AdminSet
      sets << ', ' + object&.key
    elsif object.class == ParentObject
      sets << ', ' + object.admin_set.key
    end
    split_sets = sets.split(',').uniq.reject(&:blank?)
    self.admin_set = split_sets.join(', ')
  end

  # GETS LIST OF CONNECTED STATUSES
  def connected_statuses
    @connected_statuses ||= batch_connections.where(connectable_type: "ParentObject").map(&:status)
  end

  # COUNTS CURRENT STATUSES
  def status_hash
    @status_hash ||= {
      complete: connected_statuses.count("Complete") + connected_statuses.count("Parent object deleted successfully"),
      in_progress: connected_statuses.count("In progress - no failures"),
      failed: connected_statuses.count("Failed"),
      unknown: connected_statuses.count("Unknown"),
      total: connected_statuses.count.to_f
    }
  end
end
