# frozen_string_literal: true

class BatchProcess < ApplicationRecord # rubocop:disable Metrics/ClassLength
  attr_reader :file
  after_create :determine_background_jobs
  before_create :mets_oid
  validate :validate_import
  belongs_to :user, class_name: "User"
  has_many :batch_connections
  has_many :parent_objects, through: :batch_connections, source_type: "ParentObject", source: :connectable

  def self.batch_actions
    ['create parent objects', 'export child oids']
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
      self[:csv] = value.read
    elsif File.extname(file) == '.xml'
      self[:mets_xml] = value.read
    end
  end

  def parsed_csv
    @parsed_csv ||= CSV.parse(csv, headers: true) if csv.present?
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

  def output_csv
    return nil unless batch_action == "export child oids"
    headers = ["child_oid", "parent_oid", "order", "parent_title", "label", "caption", "viewing_hint"]
    csv_string = CSV.generate do |csv|
      csv << headers
      oids.each do |oid|
        begin
          po = ParentObject.find(oid.to_i)
          po.child_objects.each do |co|
            row = [co.oid, po.oid, co.order, po.authoritative_json["title"]&.first, co.label, co.caption, co.viewing_hint]
            csv << row
          end
        rescue ActiveRecord::RecordNotFound
          row = ["Parent Not Found in database", oid, "", "", "", ""]
          csv << row
        end
      end
      csv_string
    end
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

  def setup_for_background_jobs(parent_object, metadata_source)
    parent_object.authoritative_metadata_source = MetadataSource.find_by(metadata_cloud_name: (metadata_source.presence || 'ladybird'))
    parent_object.current_batch_process = self
    parent_object.current_batch_connection = batch_connections.build(connectable: parent_object)
  end

  def refresh_metadata_cloud_csv
    metadata_sources = parsed_csv.entries.map { |r| r['Source'] }
    create_parent_objects_from_oids(oids, metadata_sources)
  end

  def refresh_metadata_cloud_mets
    fresh = false
    metadata_source = mets_doc.metadata_source
    po = ParentObject.where(oid: oid).first_or_create do |parent_object|
      # Only runs on newly created parent objects
      parent_object.bib = mets_doc.bib
      parent_object.visibility = mets_doc.visibility
      parent_object.rights_statement = mets_doc.rights_statement
      parent_object.viewing_direction = mets_doc.viewing_direction
      parent_object.display_layout = mets_doc.viewing_hint
      setup_for_background_jobs(parent_object, metadata_source)
      fresh = true
      parent_object.from_mets = true
      parent_object.representative_child_oid = mets_doc.thumbnail_image
    end
    return if fresh
    po.metadata_update = true
    setup_for_background_jobs(po, metadata_source)
    po.save!
  end

  def determine_background_jobs
    if csv.present? && (batch_action.eql? 'create parent objects')
      RefreshMetadataCloudCsvJob.perform_later(self)
    elsif csv.present? && (batch_action.eql? 'export child oids')
      CreateChildOidCsvJob.perform_later(self)
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
    @connected_statuses ||= batch_connections.map(&:status)
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
end
