# frozen_string_literal: true

class GoobiXmlImport < ApplicationRecord
  attr_reader :file
  before_create :file
  validate :oid, :valid_mets?, :all_images_present?

  def file=(value)
    @file = value
    self[:goobi_xml] = value.read
  end

  def oid
    mets_doc = MetsDocument.new(@file)
    return errors.add(:file, 'must contain an oid') if mets_doc.oid.nil? || mets_doc.oid.empty?
    mets_doc.oid
  end

  def valid_mets?
    mets_doc = MetsDocument.new(@file)
    return errors.add(:file, 'must be a valid Goobi METs file') unless mets_doc.valid_mets?
  end

  def all_images_present?
    mets_doc = MetsDocument.new(@file)
    return errors.add(:file, 'all image files must be available to the application') unless mets_doc.all_images_present?
  end

  def refresh_metadata_cloud
    MetadataCloudService.create_parent_objects_from_oids([oid], 'ladybird') # TODO: make 'ladybird' a metadata source attribute on this object
  end
end
