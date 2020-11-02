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

  def kind
    if csv.present?
      'CSV'
    elsif mets_xml.present?
      'METS'
    else
      'Unknown'
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
      po = ParentObject.where(oid: oid).first_or_create do |parent_object|
        parent_object.authoritative_metadata_source = if metadata_source.present?
                                                        MetadataSource.find_by(metadata_cloud_name: metadata_source)
                                                      else
                                                        MetadataSource.find_by(metadata_cloud_name: 'ladybird')
                                                      end
        parent_object.current_batch_process = self
      end
      batch_connections.build(connectable: po)
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
    if single_status
      single_status
    elsif statuses[:failed] != 0
      percent = ((statuses[:failed] / statuses[:total]) * 100).round
      "#{percent}% of parent objects have a failure."
    else
      "Batch status unknown"
    end
  end

  def single_status
    if statuses[:in_progress] / statuses[:total] == 1
      "Batch in progress - no failures"
    elsif statuses[:complete] / statuses[:total] == 1
      "Batch complete"
    elsif statuses[:failed] / statuses[:total] == 1
      "Batch failed"
    end
  end

  def statuses
    connected_statuses = batch_connections.map do |batch_connection|
      batch_connection.connectable&.status_for_batch_process(batch_connection.batch_process_id)
    end
    {
      complete: connected_statuses.count("Complete"),
      in_progress: connected_statuses.count("In progress - no failures"),
      failed: connected_statuses.count("Failed"),
      unknown: connected_statuses.count("Unknown"),
      total: connected_statuses.count.to_f
    }
  end
end
