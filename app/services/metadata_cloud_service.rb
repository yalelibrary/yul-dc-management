# frozen_string_literal: true
require 'csv'

class MetadataCloudService
  ##
  # This is the method that is called from the yale:refresh_fixture_data rake task
  def self.refresh_fixture_data(oid_path, metadata_source)
    mcs = MetadataCloudService.new
    mcs.list_of_oids(oid_path).each do |oid|
      next unless mcs.build_metadata_cloud_url(oid, metadata_source)
      metadata_cloud_url = mcs.build_metadata_cloud_url(oid, metadata_source)
      full_response = mcs.mc_get(metadata_cloud_url)
      mcs.save_mc_json_to_file(full_response, oid, metadata_source)
    end
  end

  ##
  # Takes a Metadata Cloud formatted url and returns the full HTTP response with headers
  def mc_get(mc_url)
    metadata_cloud_username = ENV["MC_USER"]
    metadata_cloud_password = ENV["MC_PW"]
    HTTP.basic_auth(user: metadata_cloud_username, pass: metadata_cloud_password).get(mc_url)
  end

  ##
  # Takes an oid (Ladybird identifier) and a metadata source (allowed values are ladybird, ils, and aspace), and returns
  # the appropriate URL to pull the metadata from the Yale Metadata Cloud
  def build_metadata_cloud_url(oid, metadata_source)
    if metadata_source == "ladybird"
      identifier_block = "/oid/#{oid}"
    elsif metadata_source == "ils"
      bib = get_bib(oid)
      barcode = get_barcode(oid)
      identifier_block = if barcode.nil?
                           "/bib/#{bib}"
                         else
                           "/barcode/#{barcode}?bib=#{bib}"
                         end
    elsif metadata_source == "aspace"
      return nil unless get_archive_space_uri(oid)
      identifier_block = get_archive_space_uri(oid)
    end
    "https://metadata-api-test.library.yale.edu/metadatacloud/api/#{metadata_source}#{identifier_block}"
  end

  def find_source_ids_for(oid)
    ladybird_hash = fixture_file_to_hash(oid, "ladybird")
    bib = ladybird_hash["orbisRecord"]
    barcode = ladybird_hash["orbisBarcode"]
    # May not have both holding and item even with barcode
    if bib && barcode
      voyager_hash = fixture_file_to_hash(oid, "ils")
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

  def self.find_source_ids
    mcs = MetadataCloudService.new
    parent_objects = ParentObject.all
    parent_objects.each do |parent_object|
      oid = parent_object["oid"]
      mcs.find_source_ids_for(oid)
    end
  end

  def get_archive_space_uri(oid)
    ladybird_hash = fixture_file_to_hash(oid, "ladybird")
    ladybird_hash["archiveSpaceUri"]
  end

  ##
  # Takes an oid and returns the corresponding bib, as defined by ladybird
  # I suspect this approach is going to be super slow, should probably decide how long we want to keep these and figure out
  # how we want to save them. Like, should refreshing the relationship between the Ladybird IDs and the bib ids be done on a chron job?
  def get_bib(oid)
    ladybird_hash = fixture_file_to_hash(oid, "ladybird")
    ladybird_hash["orbisRecord"]
  end

  def get_barcode(oid)
    ladybird_hash = fixture_file_to_hash(oid, "ladybird")
    ladybird_hash["orbisBarcode"]
  end

  ##
  # Takes a full HTTP response with headers and saves a json file
  def save_mc_json_to_file(mc_response, oid, metadata_source)
    file_folder = Rails.root.join("spec", "fixtures", metadata_source)
    raw_metadata = mc_response.body.to_str
    parsed_metadata = JSON.parse(raw_metadata)
    file_prefix = file_prefix(metadata_source)

    File.write(file_folder.join("#{file_prefix}#{oid}" + ".json"), JSON.pretty_generate(parsed_metadata))
  end

  ##
  # Takes a csv file and returns an array containing the values from the first column
  def build_oid_array(oid_path)
    fixture_ids_table = CSV.read(oid_path, headers: true)
    fixture_ids_table.by_col[0]
  end

  ##
  # Takes a csv file
  def list_of_oids(oid_path)
    @list_of_oids ||= build_oid_array(oid_path)
  end

  ##
  # Takes an oid and a metadata_source and returns a hash of the fixture file associated with that oid and metadata_source
  def fixture_file_to_hash(oid, metadata_source)
    fixture_file_folder = Rails.root.join("spec", "fixtures", metadata_source)
    file_prefix = file_prefix(metadata_source)
    file_path = fixture_file_folder.join("#{file_prefix}#{oid}" + ".json")
    return false unless File.exist?(file_path)
    fixture_file = File.read(file_path)
    JSON.parse(fixture_file)
  end

  def file_prefix(metadata_source)
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
