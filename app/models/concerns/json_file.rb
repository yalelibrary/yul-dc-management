# frozen_string_literal: true

module JsonFile
  extend ActiveSupport::Concern

  def to_json_file(folder = nil)
    folder ||= Rails.root.join("spec", "fixtures", authoritative_metadata_source.metadata_cloud_name)
    file_prefix = authoritative_metadata_source.file_prefix
    File.write(folder.join("#{file_prefix}#{oid}.json"), JSON.pretty_generate(authoritative_json))
  end
end
