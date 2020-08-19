# frozen_string_literal: true

class MetsXmlImport < ApplicationRecord
  attr_reader :file
  validate :validate_upload
  after_create :refresh_metadata_cloud

  def file=(value)
    @file = value
    self[:mets_xml] = value.read
  end

  def oid
    self[:oid] = mets_doc.oid.to_i
  end

  def mets_doc
    @mets_doc ||= MetsDocument.new(mets_xml)
  end

  def validate_upload
    return errors.add(:file, 'must contain an oid') if mets_doc.oid.nil? || mets_doc.oid.empty?
    return errors.add(:file, 'must be a valid METs file') unless mets_doc.valid_mets?
    return errors.add(:file, 'all image files must be available to the application') unless mets_doc.all_images_present?
  end

  def refresh_metadata_cloud
    MetadataCloudService.create_parent_objects_from_oids([mets_doc.oid], 'ladybird') # TODO: make 'ladybird' a metadata source attribute on this object
  end
end
