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
    ['create parent objects', 'update parent objects', 'update child objects caption and label', 'update IIIF manifests', 'delete parent objects', 'delete child objects', 'export all parent objects by admin set',
     'export child oids', 'reassociate child oids', 'recreate child oid ptiffs', 'update fulltext status', 'resync with preservica']
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
      begin
          mets_doc.valid_mets?
      rescue => error
        return errors.add(:file, error)
        end
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
      when 'export all parent objects by admin set'
        CreateParentOidCsvJob.perform_later(self)
      when 'export child oids'
        CreateChildOidCsvJob.perform_later(self)
      when 'update parent objects'
        UpdateParentObjectsJob.perform_later(self)
      when 'update child objects caption and label'
        UpdateChildObjectsJob.perform_later(self)
      when 'update IIIF manifests'
        UpdateManifestsJob.perform_later(self)
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

  # CREATE PARENT OBJECTS: ------------------------------------------------------------------------- #

  # CREATES PARENT OBJECTS FROM INGESTED CSV
  # rubocop:disable  Metrics/AbcSize
  # rubocop:disable  Metrics/MethodLength
  # rubocop:disable  Metrics/PerceivedComplexity
  # rubocop:disable  Metrics/CyclomaticComplexity
  def create_new_parent_csv
    self.admin_set = ''
    sets = admin_set
    parsed_csv.each_with_index do |row, index|
      if row['digital_object_source'].present? && row['preservica_uri'].present?
        begin
          parent_object = CsvRowParentService.new(row, index, current_ability, user).parent_object
          setup_for_background_jobs(parent_object, row['source'])
        rescue CsvRowParentService::BatchProcessingError => e
          batch_processing_event(e.message, e.kind)
          next
        rescue PreservicaImageService::PreservicaImageServiceError => e
          batch_processing_event("Skipping row [#{index + 2}] #{e.message}.", "Skipped Row")
          next
        end
      else
        oid = row['oid']
        metadata_source = row['source']
        model = row['parent_model'] || 'complex'
        admin_set = editable_admin_set(row['admin_set'], oid, index)
        next unless admin_set
        sets << ', ' + admin_set&.key
        split_sets = sets.split(',').uniq.reject(&:blank?)
        self.admin_set = split_sets.join(', ')
        save!

        parent_object = ParentObject.find_or_initialize_by(oid: oid)
        # Only runs on newly created parent objects
        unless parent_object.new_record?
          batch_processing_event("Skipping row [#{index + 2}] with existing parent oid: #{oid}", 'Skipped Row')
          next
        end

        parent_object.parent_model = model

        setup_for_background_jobs(parent_object, metadata_source)
        parent_object.admin_set = admin_set
        # TODO: enable edit action when added to batch actions
      end
      begin
        parent_object.save!
      rescue StandardError => e
        batch_processing_event("Skipping row [#{index + 2}] Unable to save parent: #{e.message}.", "Skipped Row")
      end
    end
  end
  # rubocop:enable  Metrics/AbcSize
  # rubocop:enable  Metrics/MethodLength
  # rubocop:enable  Metrics/PerceivedComplexity
  # rubocop:enable  Metrics/CyclomaticComplexity

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
    object.current_batch_connection = batch_connections.find_by(connectable: object) || batch_connections.build(connectable: object)
    object.current_batch_connection.save!
  end

  # RECREATE CHILD OID PTIFFS: -------------------------------------------------------------------- #

  # RECREATES CHILD OID PTIFFS FROM INGESTED CSV
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def update_fulltext_status(offset = 0, limit = -1)
    job_oids = oids
    job_oids = job_oids.drop(offset) if offset&.positive?
    job_oids = job_oids.first(limit) if limit&.positive?
    self.admin_set = ''
    sets = admin_set
    job_oids.each_with_index do |parent_oid, index|
      parent_object = ParentObject.find_by(oid: parent_oid)
      if parent_object.nil?
        batch_processing_event("Skipping row [#{index + 2}] because unknown parent: #{parent_oid}", 'Unknown Parent')
      elsif current_ability.can?(:update, parent_object)
        attach_item(parent_object)

        sets << ', ' + AdminSet.find(parent_object.authoritative_metadata_source_id).key
        split_sets = sets.split(',').uniq.reject(&:blank?)
        self.admin_set = split_sets.join(', ')
        save!

        parent_object.child_objects.each { |co| attach_item(co) }
        parent_object.processing_event("Parent #{parent_object.oid} is being processed", 'processing-queued')
        parent_object.update_fulltext_for_children
        parent_object.processing_event("Parent #{parent_object.oid} has been updated", 'update-complete')
      else
        batch_processing_event("Skipping row [#{index + 2}] because #{user.uid} does not have permission to create or update parent: #{parent_oid}", 'Permission Denied')
      end
    end
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

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
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def recreate_child_oid_ptiffs
    parents = Set[]
    self.admin_set = ''
    sets = admin_set
    oids.each_with_index do |oid, index|
      child_object = ChildObject.find_by_oid(oid.to_i)
      unless child_object
        batch_processing_event("Skipping row [#{index + 2}] with unknown Child: #{oid}", 'Skipped Row')
        next
      end
      next unless child_object

      sets << ', ' + child_object.parent_object.admin_set.key
      split_sets = sets.split(',').uniq.reject(&:blank?)
      self.admin_set = split_sets.join(', ')
      save!

      configure_parent_object(child_object, parents)
      attach_item(child_object)
      next unless user_update_child_permission(child_object, child_object.parent_object)
      path = Pathname.new(child_object.access_master_path)
      file_size = File.exist?(path) ? File.size(path) : 0
      GeneratePtiffJob.set(queue: :large_ptiff).perform_later(child_object, self) if file_size > SetupMetadataJob::ONE_GB
      GeneratePtiffJob.perform_later(child_object, self) if file_size <= SetupMetadataJob::ONE_GB
      attach_item(child_object)
      child_object.processing_event("Ptiff Queued", "ptiff-queued")
    end
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

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
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Rails/SaveBang
  def refresh_metadata_cloud_mets
    metadata_source = mets_doc.metadata_source
    self.admin_set = ''
    sets = admin_set
    if ParentObject.exists?(oid: oid)
      batch_processing_event("Skipping mets import for existing parent: #{oid}", 'Skipped Import')
      return
    end
    ParentObject.create(oid: oid) do |parent_object|
      set_values_from_mets(parent_object, metadata_source)
      if parent_object.admin_set.present?
        sets << ', ' + parent_object.admin_set.key
        split_sets = sets.split(',').uniq.reject(&:blank?)
        self.admin_set = split_sets.join(', ')
        save
      end
    end
    PreservicaIngest.create(parent_oid: oid, preservica_id: mets_doc.parent_uuid, batch_process_id: id, ingest_time: Time.current) unless mets_doc.parent_uuid.nil?
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Rails/SaveBang

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

  # FETCHES CHILD OBJECTS FROM PRESERVICA
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def sync_from_preservica
    self.admin_set = ''
    sets = admin_set
    parsed_csv.each_with_index do |row, _index|
      begin
        parent_object = ParentObject.find(row['oid'])
        sets << ', ' + parent_object.admin_set.key
        split_sets = sets.split(',').uniq.reject(&:blank?)
        self.admin_set = split_sets.join(', ')
        save!
      rescue
        batch_processing_event("Parent OID: #{row['oid']} not found in database", 'Skipped Import') if parent_object.nil?
        next
      end
      next unless validate_preservica_sync(parent_object, row)
      local_children_hash = {}
      parent_object.child_objects.each do |local_co|
        local_children_hash["hash_#{local_co.order}".to_sym] = { order: local_co.order,
                                                                 content_uri: local_co.preservica_content_object_uri,
                                                                 generation_uri: local_co.preservica_generation_uri,
                                                                 bitstream_uri: local_co.preservica_bitstream_uri }
      end
      begin
        preservica_children_hash = {}
        PreservicaImageService.new(parent_object.preservica_uri, parent_object.admin_set.key).image_list(parent_object.preservica_representation_type).each_with_index do |preservica_co, index|
          # increment by one so index lines up with order
          index_plus_one = index + 1
          preservica_children_hash["hash_#{index_plus_one}".to_sym] = { order: index_plus_one,
                                                                        content_uri: preservica_co[:preservica_content_object_uri],
                                                                        generation_uri: preservica_co[:preservica_generation_uri],
                                                                        bitstream_uri: preservica_co[:preservica_bitstream_uri] }
        end
      rescue PreservicaImageService::PreservicaImageServiceNetworkError => e
        batch_processing_event("Parent OID: #{row['oid']} because of #{e.message}", 'Skipped Import')
        raise
      rescue PreservicaImageService::PreservicaImageServiceError => e
        batch_processing_event("Parent OID: #{row['oid']} because of #{e.message}", 'Skipped Import')
        next
      end
      sync_images_preservica(local_children_hash, preservica_children_hash, parent_object)
    end
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize

  # SYNC IMAGES FROM PRESERVICA
  def sync_images_preservica(local_children_hash, preservica_children_hash, parent_object)
    if local_children_hash != preservica_children_hash
      setup_for_background_jobs(parent_object, parent_object.source_name)
      parent_object.sync_from_preservica(local_children_hash, preservica_children_hash)
    elsif fails_fixity_check(parent_object)
      batch_processing_event("Checksum mismatch found on parent object: #{parent_object.oid}", "Row Processed")
    else
      batch_processing_event("Child object count and order is the same.  No update needed.", "Skipped Row")
    end
  end

  def fails_fixity_check(parent_object)
    # iterate through images in pairtree and get checksums
    local_checksums = []
    parent_object.child_objects.each do |co|
      local_checksums << co.sha512_checksum
    end
    # iterate through preservica images and get checksums
    preservica_checksums = []
    PreservicaImageService.new(parent_object.preservica_uri, parent_object.admin_set.key).image_list(parent_object.preservica_representation_type).each do |preservica_co|
      preservica_checksums << preservica_co[:sha512_checksum]
    end
    # compare and return true if there is a mismatch
    if local_checksums != preservica_checksums
      true
    else
      false
    end
  end

  # rubocop:disable Metrics/MethodLength
  # ERROR HANDLING FOR PRESERVICA SYNC
  def validate_preservica_sync(parent_object, row)
    if parent_object.redirect_to.present?
      batch_processing_event("Parent OID: #{row['oid']} is a redirected parent object", 'Skipped Import')
      false
    elsif parent_object.preservica_uri.nil?
      batch_processing_event("Parent OID: #{row['oid']} does not have a Preservica URI", 'Skipped Import')
      false
    elsif parent_object.digital_object_source != "Preservica"
      batch_processing_event("Parent OID: #{row['oid']} does not have a Preservica digital object source", 'Skipped Import')
      false
    elsif parent_object.preservica_representation_type.nil?
      batch_processing_event("Parent OID: #{row['oid']} does not have a Preservica representation type", 'Skipped Import')
      false
    elsif !parent_object.admin_set.preservica_credentials_verified
      batch_processing_event("Admin set #{parent_object.admin_set.key} does not have Preservica credentials set", 'Skipped Import')
      false
    elsif !current_ability.can?(:update, parent_object)
      batch_processing_event("Skipping row with parent oid: #{parent_object.oid}, user does not have permission to update", 'Permission Denied')
      false
    else
      true
    end
  end
  # rubocop:enable Metrics/MethodLength

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
