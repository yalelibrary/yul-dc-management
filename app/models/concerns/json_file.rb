# frozen_string_literal: true

module JsonFile
  extend ActiveSupport::Concern

  def to_json_file(args={})
    metadata_source = args[:metadata_source] || authoritative_metadata_source
    json_to_use = json_for(metadata_source.metadata_cloud_name)
    if json_to_use.present?
      args[:folder] ||= Rails.root.join("spec", "fixtures", metadata_source.metadata_cloud_name)
      file_prefix = metadata_source.file_prefix
      File.write(args[:folder].join("#{file_prefix}#{oid}.json"), JSON.pretty_generate(json_to_use))
    end
  end
end
