# frozen_string_literal: true

class BatchProcess < ApplicationRecord
  attr_reader :file, :created_by_id
  after_create :refresh_metadata_cloud
  validate :validate_import
  belongs_to :user, class_name: "User"

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

  def user
    @user ||= User.find(user_id)
  end

  def user_id=(current_user_id)
    @user_id = current_user_id
    self[:user_id] = current_user_id
  end

  def file=(value)
    @file = value
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

  def refresh_metadata_cloud_csv
    oids = parsed_csv.entries.map { |r| r['oid'] }
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
