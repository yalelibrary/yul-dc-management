# frozen_string_literal: true
require 'csv'

class FixtureParsingService
  ##
  # Takes an oid and a metadata_source and returns a hash of the fixture file associated with that oid and metadata_source
  def self.fixture_file_to_hash(oid, metadata_source)
    fixture_file_folder = Rails.root.join("spec", "fixtures", metadata_source)
    file_path = fixture_file_folder.join("#{file_prefix(metadata_source)}#{oid}" + ".json")
    return false unless File.exist?(file_path)
    fixture_file = File.read(file_path)
    JSON.parse(fixture_file)
  end

  def self.find_dependent_uris(metadata_source)
    parent_objects = ParentObject.all
    parent_objects.each do |parent_object|
      oid = parent_object["oid"]
      find_dependent_uri_for(oid, metadata_source)
    end
  end

  def self.find_dependent_uri_for(oid, metadata_source)
    hash = fixture_file_to_hash(oid, metadata_source)
    return unless hash
    hash["dependentUris"].each do |uri|
      dep_obj = DependentObject.find_or_create_by(
        dependent_uri: uri,
        metadata_source: metadata_source,
        parent_object_id: oid
      )
      dep_obj.save
    end
  end

  ##
  # Takes a csv file and returns an array containing the values from the first column
  def self.build_oid_array(oid_path)
    fixture_ids_table = CSV.read(oid_path, headers: true)
    fixture_ids_table.by_col[0]
  end

  def self.file_prefix(metadata_source)
    case metadata_source
    when "ladybird"
      ""
    when "ils"
      "V-"
    when "aspace"
      "AS-"
    end
  end
end
