class OidImport < ApplicationRecord
  attr_accessor :file

  def file=(value)
    write_attribute(:csv, value.read)
  end

  def parsed_csv
    if csv.present?
      @parsed_csv ||= CSV.parse(csv, headers: true)
    end
  end

  def refresh_metadata_cloud
    MetadataCloudService.refresh_from_upload(parsed_csv, 'ladybird')  # TODO make 'ladybird' a metadata source attribute on this object
  end

end
