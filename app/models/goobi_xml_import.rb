# frozen_string_literal: true

class GoobiXmlImport < ApplicationRecord
  attr_reader :file
  before_create :file
  validate :validate_upload

  def file=(value)
    @file = value
    self[:goobi_xml] = value.read
  end

  def validate_upload
    mets_doc = MetsDocument.new(@file)
    return errors.add(:file, 'must contain an oid') if mets_doc.oid.nil? || mets_doc.oid.empty?
    return errors.add(:file, 'must be a valid Goobi METs file') unless mets_doc.valid_mets?
    return errors.add(:file, 'all image files must be available to the application') unless mets_doc.all_images_present?
  end

  def refresh_metadata_cloud
    mets_doc = MetsDocument.new(@file)
    MetadataCloudService.create_parent_objects_from_oids([mets_doc.oid], 'ladybird') # TODO: make 'ladybird' a metadata source attribute on this object
  end
end
