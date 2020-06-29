# frozen_string_literal: true
require 'csv'

class FixtureParsingService
  ##
  # Takes an oid and a metadata_source and returns a hash of the fixture file associated with that oid and metadata_source
  def self.fixture_file_to_hash(oid, metadata_source)
    fixture_file_folder = Rails.root.join("spec", "fixtures", metadata_source)
    file_prefix = FixtureParsingService.file_prefix(metadata_source)
    file_path = fixture_file_folder.join("#{file_prefix}#{oid}" + ".json")
    return false unless File.exist?(file_path)
    fixture_file = File.read(file_path)
    JSON.parse(fixture_file)
  end

  def self.find_source_ids
    seed_database if ParentObject.count.zero?
    parent_objects = ParentObject.all
    parent_objects.each do |parent_object|
      oid = parent_object["oid"]
      find_source_ids_for(oid)
    end
  end

  def self.seed_database
    oid_path = Rails.root.join("db", "parent_oids.csv")
    fixture_ids_table = CSV.read(oid_path, headers: true)
    oids = fixture_ids_table.by_col[0]
    oids.each do |row|
      po = ParentObject.new
      po.oid = row
      po.save
    end
  end

  def self.find_source_ids_for(oid)
    ladybird_hash = FixtureParsingService.fixture_file_to_hash(oid, "ladybird")
    bib = ladybird_hash["orbisRecord"]
    barcode = ladybird_hash["orbisBarcode"]
    if bib && barcode
      voyager_hash = FixtureParsingService.fixture_file_to_hash(oid, "ils")
      holding = voyager_hash["holdingId"]
      item = voyager_hash["itemId"]
    end
    po = ParentObject.find_by(oid: oid)
    po.update(
      bib: ladybird_hash["orbisRecord"],
      barcode: ladybird_hash["orbisBarcode"],
      aspace_uri: ladybird_hash["archiveSpaceUri"],
      holding: holding,
      item: item,
      visibility: ladybird_hash["itemPermission"],
      last_id_update: DateTime.current
    )
    po.save
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
