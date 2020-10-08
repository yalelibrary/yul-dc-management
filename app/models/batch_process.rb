# frozen_string_literal: true

class BatchProcess < ApplicationRecord
  attr_reader :file
  after_create :refresh_metadata_cloud
  after_save :create_batch_process_events
  validate :validate_import
  belongs_to :user, class_name: "User"
  has_many :batch_process_events

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

  def create_batch_process_events
    oids.each do |oid|
      batch_process_events.build(
        parent_object_oid: oid,
        batch_process_id: self[:id]
      )
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

  def oid
    self[:oid] = mets_doc.oid.to_i
  end

  def parsed_csv
    @parsed_csv ||= CSV.parse(csv, headers: true) if csv.present?
  end

  def mets_doc
    @mets_doc ||= MetsDocument.new(mets_xml) if mets_xml.present?
  end

  def oids
    return @oids ||= parsed_csv.entries.map { |r| r['oid'] } unless csv.nil?
    @oids ||= [oid] unless mets_xml.nil?
  end

  def refresh_metadata_cloud_csv
    metadata_sources = parsed_csv.entries.map { |r| r['Source'] }
    MetadataCloudService.create_parent_objects_from_oids(oids, metadata_sources)
  end

  def refresh_metadata_cloud_mets
    MetadataCloudService.create_parent_objects_from_oids([mets_doc.oid], ['ladybird']) # TODO: make 'ladybird' a metadata source attribute on this object
  end

  def refresh_metadata_cloud
    if csv.present?
      refresh_metadata_cloud_csv
    elsif mets_xml.present?
      refresh_metadata_cloud_mets
    end
  end
end
