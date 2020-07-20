class GoobiXmlImport < ApplicationRecord
  attr_reader :file
  before_create :file

  def file=(value)
    @file = value
    self[:goobi_xml] = value.read
  end
end
