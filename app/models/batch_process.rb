# frozen_string_literal: true

class BatchProcess < ApplicationRecord # rubocop:disable Metrics/ClassLength
  # CSV EXPORT CHILD OIDS:
  include CsvExportable
  # DELETE PARENT / CHILD OBJECTS:
  include Deletable
  # REASSOCIATE CHILD OIDS:
  include Reassociatable
  include Statable
  # UPDATE PARENT OBJECTS:
  include Updatable
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
  def self.batch_actions
    ['create parent objects', 'update parent objects', 'delete parent objects', 'delete child objects','export child oids', 'reassociate child oids', 'recreate child oid ptiffs', 'update fulltext status']
  end

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
      return errors.add(:file, 'must be a valid METs file') unless mets_doc.valid_mets?
    else
      return errors.add(:file, 'not a valid file type. Must be a CSV or XML.')
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

  # APPENDS ID TO CSV FILENAME
  def created_file_name
    return nil unless file_name
    "#{file_name.delete_suffix('.csv')}_bp_#{id}.csv"
  end

  # FETCHES USERS ABILITIES
  def current_ability
    @current_ability ||= Ability.new(user)
  end

  # ASSIGNS PARENT/CHILD OBJECT TO BATCH PROCESS FOR REASSOCIATE/RECREATE CHILD PTIFF
  def attach_item(connectable)
    connectable.current_batch_process = self
    connectable.current_batch_connection = batch_connections.find_or_create_by(connectable: connectable)
    connectable.current_batch_connection.save!
  end

  # ASSIGN JOBS TO BATCH ACTIONS
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/MethodLength
  def determine_background_jobs
    if csv.present? && check_csv_size
      case batch_action
      when 'create parent objects'
        CreateNewParentJob.perform_later(self)
      when 'delete parent objects'
        DeleteParentObjectsJob.perform_later(self)
      when 'delete child objects'
        DeleteChildObjectsJob.perform_later(self)
      when 'export child oids'
        CreateChildOidCsvJob.perform_later(self)
      when 'update parent objects'
        UpdateParentObjectsJob.perform_later(self)
      when 'reassociate child oids'
        ReassociateChildOidsJob.perform_later(self)
      when 'recreate child oid ptiffs'
        RecreateChildOidPtiffsJob.perform_later(self)
      end
    elsif mets_xml.present?
      refresh_metadata_cloud_mets
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/MethodLength

  # CREATE PARENT OBJECTS: ------------------------------------------------------------------------- #

  # CREATES PARENT OBJECTS FROM INGESTED CSV
  def create_new_parent_csv
    parsed_csv.each_with_index do |row, index|
      oid = row['oid']
      metadata_source = row['source']
      admin_set = editable_admin_set(row['admin_set'], oid, index)
      next unless admin_set

      parent_object = ParentObject.find_or_initialize_by(oid: oid)
      # Only runs on newly created parent objects
      unless parent_object.new_record?
        batch_processing_event("Skipping row [#{index + 2}] with existing parent oid: #{oid}", 'Skipped Row')
        next
      end

      setup_for_background_jobs(parent_object, metadata_source)
      parent_object.admin_set = admin_set
      parent_object.save
      # TODO: enable edit action when added to batch actions
    end
  end

  # CHECKS TO SEE IF USER HAS ABILITY TO EDIT AN ADMIN SET:
  def editable_admin_set(admin_set_key, oid, index)
    admin_sets_hash = {}
    admin_sets_hash[admin_set_key] ||= AdminSet.find_by(key: admin_set_key)
    admin_set = admin_sets_hash[admin_set_key]
    if admin_set.blank?
      batch_processing_event("Skipping row [#{index + 2}] with unknown admin set [#{admin_set_key}] for parent: #{oid}", 'Skipped Row')
      return false
    elsif !current_ability.can?(:add_member, admin_set)
      batch_processing_event("Skipping row [#{index + 2}] because #{user.uid} does not have permission to create or update parent: #{oid}", 'Permission Denied')
      return false
    else
      admin_set
    end
  end

  # SHARED BY DELETE, CREATE, AND UPDATE: --------------------------------------------------------- #

  # ASSIGNS PARENT/CHILD OBJECT TO BATCH PROCESS FOR CREATE/DELETE/UPDATE
  def setup_for_background_jobs(object, metadata_source)
    object.authoritative_metadata_source = MetadataSource.find_by(metadata_cloud_name: (metadata_source.presence || 'ladybird')) if object.class == ParentObject
    object.current_batch_process = self
    object.current_batch_connection = batch_connections.build(connectable: object)
    object.current_batch_connection.save! if object.class == ChildObject
  end

  # DELETE PARENT OBJECTS: ------------------------------------------------------------------------ #

  # DELETES PARENT OBJECTS FROM INGESTED CSV
  def delete_objects
    parsed_csv.each_with_index do |row, index|
      oid = row['oid']
      action = row['action']
      metadata_source = row['source']
      batch_processing_event("Skipping row [#{index + 2}] with parent oid: #{oid}, action value for oid must be 'delete' to complete deletion.", 'Invalid Vocab') if action != "delete"
      next unless action == 'delete'
      parent_object = deletable_parent_object(oid, index)
      next unless parent_object
      setup_for_background_jobs(parent_object, metadata_source)
      parent_object.destroy
      parent_object.processing_event("Parent #{parent_object.oid} has been deleted", 'deleted')
    end
  end

  # CHECKS TO SEE IF USER HAS ABILITY TO DELETE OBJECTS:
  def deletable_parent_object(oid, index)
    parent_object = ParentObject.find_by(oid: oid)
    if parent_object.blank?
      batch_processing_event("Skipping row [#{index + 2}] with parent oid: #{oid} because it was not found in local database", 'Skipped Row')
      return false
    elsif !current_ability.can?(:destroy, parent_object)
      batch_processing_event("Skipping row [#{index + 2}] with parent oid: #{oid}, user does not have permission to delete.", 'Permission Denied')
      return false
    else
      parent_object
    end
  end

  # SHARED BY DELETE, CREATE, AND UPDATE: --------------------------------------------------------- #

  # ASSIGNS PARENT/CHILD OBJECT TO BATCH PROCESS FOR CREATE/DELETE/UPDATE
  def setup_for_background_jobs(object, metadata_source)
    object.authoritative_metadata_source = MetadataSource.find_by(metadata_cloud_name: (metadata_source.presence || 'ladybird')) if object.class == ParentObject
    object.current_batch_process = self
    object.current_batch_connection = batch_connections.build(connectable: object)
    return unless object.class == ChildObject

    object.full_text = object.remote_ocr
    object.current_batch_connection.save!
  end

  # CHECKS THAT METADATA SOURCE IS VALID - USED BY UPDATE
  def validate_metadata_source(metadata_source, index)
    if metadata_source == 'aspace' || metadata_source == 'ils' || metadata_source == 'ladybird'
      true
    else
      batch_processing_event("Skipping row [#{index + 2}] with unknown metadata source: #{metadata_source}.  Accepted values are 'ladybird', 'aspace', or 'ils'.", 'Skipped Row')
      false
    end
  end

  # RECREATE CHILD OID PTIFFS: -------------------------------------------------------------------- #

  # RECREATES CHILD OID PTIFFS FROM INGESTED CSV
  def update_fulltext_status
    oids.each_with_index do |parent_oid, index|
      parent_object = ParentObject.find_by(oid: parent_oid)
      if parent_object.nil?
        batch_processing_event("Skipping row [#{index + 2}] because unknown parent: #{parent_oid}", 'Unknown Parent')
      elsif current_ability.can?(:update, parent_object)
        attach_item(parent_object)
        parent_object.child_objects.each { |co| attach_item(co) }
        parent_object.processing_event("Parent #{parent_object.oid} is being processed", 'processing-queued')
        parent_object.update_fulltext_for_children
        parent_object.processing_event("Parent #{parent_object.oid} has been updated", 'update-complete')
      else
        batch_processing_event("Skipping row [#{index + 2}] because #{user.uid} does not have permission to create or update parent: #{parent_oid}", 'Permission Denied')
      end
    end
  end

  # RECREATE CHILD OID PTIFFS: -------------------------------------------------------------------- #

  # RECREATES CHILD OID PTIFFS FROM INGESTED CSV
  def recreate_child_oid_ptiffs
    parents = Set[]
    oids.each_with_index do |oid, index|
      child_object = ChildObject.find_by_oid(oid.to_i)
      unless child_object
        batch_processing_event("Skipping row [#{index + 2}] with unknown Child: #{oid}", 'Skipped Row')
        next
      end
      next unless child_object

      configure_parent_object(child_object, parents)
      attach_item(child_object)
      next unless user_update_child_permission(child_object, child_object.parent_object)

      GeneratePtiffJob.perform_later(child_object, self)
      attach_item(child_object)
      child_object.processing_event("Ptiff Queued", "ptiff-queued")
    end
  end

  # SETS COMPLETE STATUS FOR RECREATE JOB
  def are_all_children_complete?(parent_object)
    child_objects.where(parent_object: parent_object).all? do |co|
      co.status_for_batch_process(self) == 'Complete'
    end
  end

  # CHECKS TO SEE IF USER HAS THE ABILITY TO UPDATE CHILD OBJECTS:
  def user_update_child_permission(child_object, parent_object)
    user = self.user
    unless current_ability.can? :update, child_object
      batch_processing_event("#{user.uid} does not have permission to update Child: #{child_object.oid} on Parent: #{child_object.parent_object.oid}", 'Permission Denied')
      child_object.processing_event("#{user.uid} does not have permission to update Child: #{child_object.oid}", 'Permission Denied')
      parent_object.processing_event("#{user.uid} does not have permission to update Child: #{child_object.oid}", 'Permission Denied')
      return false
    end

    true
  end

  # USED BY RECREATE CHILD OID PTIFF BATCH PROCESS: ----------------------------------------------- #

  # CONNECTS CHILD OIDS BATCH PROCESS TO PARENT OBJECT
  def configure_parent_object(child_object, parents)
    parent_object = child_object.parent_object
    unless parents.include? parent_object.oid
      attach_item(parent_object)
      parent_object.processing_event("Connection to batch created", "parent-connection-created")
      parents.add parent_object.oid
    end

    parents
  end

  # METS METADATA CLOUD: ------------------------------------------------------------------------- #

  # MAKES CALL FOR UPDATED DATA
  def refresh_metadata_cloud_mets
    metadata_source = mets_doc.metadata_source
    if ParentObject.exists?(oid: oid)
      batch_processing_event("Skipping mets import for existing parent: #{oid}", 'Skipped Import')
      return
    end
    ParentObject.create(oid: oid) do |parent_object|
      set_values_from_mets(parent_object, metadata_source)
    end
    PreservicaIngest.create(parent_oid: oid, preservica_id: mets_doc.parent_uuid, batch_process_id: id, ingest_time: Time.current) unless mets_doc.parent_uuid.nil?
  end

  # SETS VALUES FROM METS METADATA
  # rubocop:disable Metrics/AbcSize
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
    parent_object.admin_set = mets_doc.admin_set
    parent_object.extent_of_digitization = mets_doc.extent_of_dig
    parent_object.digitization_note = mets_doc.dig_note
  end
  # rubocop:enable Metrics/AbcSize

  # BATCH STATUSES: ------------------------------------------------------------------------------ #
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/MethodLength
  def determine_background_jobs
    if csv.present? && check_csv_size
      case batch_action
      when 'create parent objects'
        CreateNewParentJob.perform_later(self)
      when 'delete parent objects'
        DeleteObjectsJob.perform_later(self)
      when 'export child oids'
        CreateChildOidCsvJob.perform_later(self)
      when 'update parent objects'
        UpdateParentObjectsJob.perform_later(self)
      when 'reassociate child oids'
        ReassociateChildOidsJob.perform_later(self)
      when 'recreate child oid ptiffs'
        RecreateChildOidPtiffsJob.perform_later(self)
      when 'update fulltext status'
        update_fulltext_status
      end
    elsif mets_xml.present?
      refresh_metadata_cloud_mets
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/MethodLength

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
      "Batch status unknown"
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

  # GETS LIST OF CONNECTED STATUSES
  def connected_statuses
    @connected_statuses ||= batch_connections.where(connectable_type: "ParentObject").map(&:status)
  end

  # COUNTS CURRENT STATUSES
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
