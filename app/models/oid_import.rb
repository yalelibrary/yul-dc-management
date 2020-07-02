# frozen_string_literal: true

class OidImport < ApplicationRecord
  attr_accessor :file

  def file=(value)
    self[:csv] = value.read
  end

  def parsed_csv
    @parsed_csv ||= CSV.parse(csv, headers: true) if csv.present?
  end

  def refresh_metadata_cloud
    MetadataCloudService.refresh_from_upload(parsed_csv, 'ladybird') # TODO: make 'ladybird' a metadata source attribute on this object
  end
end
