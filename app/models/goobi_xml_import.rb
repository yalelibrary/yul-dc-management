# frozen_string_literal: true

class GoobiXmlImport < ApplicationRecord
  attr_reader :file
  before_create :file
  validate :check_for_oid

  def file=(value)
    @file = value
    self[:goobi_xml] = value.read
  end

  def check_for_oid
    mets_doc = MetsDocument.new(@file)
    errors.add(:file, 'must contain an oid') if mets_doc.oid.nil? || mets_doc.oid.empty?
  end
end
