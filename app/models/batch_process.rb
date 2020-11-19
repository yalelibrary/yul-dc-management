# frozen_string_literal: true

class BatchProcess < ApplicationRecord
  attr_reader :file
  after_create :refresh_metadata_cloud
  before_create :mets_oid
  validate :validate_import
  belongs_to :user, class_name: "User"
  has_many :batch_connections
  has_many :parent_objects, through: :batch_connections, source_type: "ParentObject", source: :connectable

  def validate_import
    return if file.blank?
    if File.extname(file) == '.csv'
      errors.add(:file, 'must be a csv') if CSV.read(file).blank?
    elsif File.extname(file) == '.xml'
      # return errors.add(:file, 'must contain an oid') if mets_doc.oid.nil? || mets_doc.oid.empty?
      return errors.add(:file, 'must be a valid METs file') unless mets_doc.valid_mets?
      return errors.add(:file, 'all image files must be available to the application') unless mets_doc.all_images_present?
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

  def create_parent_objects_from_oids(oids, metadata_sources)
    oids.zip(metadata_sources).each do |oid, metadata_source|
      fresh = false
      po = ParentObject.where(oid: oid).first_or_create do |parent_object|
        # Only runs on newly created parent objects
        parent_object.authoritative_metadata_source = metadata_source(parent_object, metadata_source)
        parent_object.current_batch_process = self
        parent_object.current_batch_connection = batch_connections.build(connectable: parent_object)
        fresh = true
      end
      next if fresh
      po.metadata_update = true
      po.authoritative_metadata_source = metadata_source(po, metadata_source)
      po.current_batch_process = self
      po.current_batch_connection = batch_connections.create(connectable: po)
      po.save!
    end
  end

  def metadata_source(parent_object, metadata_source_name)
    parent_object.authoritative_metadata_source = if metadata_source_name.present?
                                                    MetadataSource.find_by(metadata_cloud_name: metadata_source_name)
                                                  else
                                                    MetadataSource.find_by(metadata_cloud_name: 'ladybird')
                                                  end
  end

  def refresh_metadata_cloud_csv
    metadata_sources = parsed_csv.entries.map { |r| r['Source'] }
    create_parent_objects_from_oids(oids, metadata_sources)
  end

  def refresh_metadata_cloud_mets
    create_parent_objects_from_oids([mets_doc.oid], ['ladybird']) # TODO: make 'ladybird' a metadata source attribute on this object
  end

  def refresh_metadata_cloud
    if csv.present?
      refresh_metadata_cloud_csv
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
