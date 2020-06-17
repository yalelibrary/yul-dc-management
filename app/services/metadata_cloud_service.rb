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
      bib_id = get_bib_id(oid)
      barcode = get_barcode(oid)
      identifier_block = if barcode.nil?
                           "/bib/#{bib_id}"
                         else
                           "/barcode/#{barcode}?bib=#{bib_id}"
                         end
    elsif metadata_source == "aspace"
      return nil unless get_archive_space_uri(oid)
      identifier_block = get_archive_space_uri(oid)
    end
    "https://metadata-api-test.library.yale.edu/metadatacloud/api/#{metadata_source}#{identifier_block}"
  end

  def create_crosswalk(oid)
    ladybird_file = get_fixture_file(oid, "ladybird")
    parsed_ladybird_file = JSON.parse(ladybird_file)
    bib_id = parsed_ladybird_file["orbisRecord"]
    barcode = parsed_ladybird_file["orbisBarcode"]
    aspace_uri = parsed_ladybird_file["archiveSpaceUri"]

    po = ParentObject.find_by(oid: oid)
    po.update(
      bib_id: bib_id,
      barcode: barcode,
      aspace_uri: aspace_uri,
      last_id_upate: DateTime.current
    )
    po.save
  end

  def self.crosswalk_all_oids
    mcs = MetadataCloudService.new
    parent_objects = ParentObject.all
    parent_objects.each do |parent_object|
      oid = parent_object["oid"]
      mcs.create_crosswalk(oid)
    end
  end

  def get_archive_space_uri(oid)
    ladybird_file = get_fixture_file(oid, "ladybird")
    parsed_ladybird_file = JSON.parse(ladybird_file)
    parsed_ladybird_file["archiveSpaceUri"]
  end

  ##
  # Takes an oid and returns the corresponding bib_id, as defined by ladybird
  # I suspect this approach is going to be super slow, should probably decide how long we want to keep these and figure out
  # how we want to save them. Like, should refreshing the relationship between the Ladybird IDs and the bib ids be done on a chron job?
  def get_bib_id(oid)
    ladybird_file = get_fixture_file(oid, "ladybird")
    parsed_ladybird_file = JSON.parse(ladybird_file)
    parsed_ladybird_file["orbisRecord"]
  end

  def get_barcode(oid)
    ladybird_file = get_fixture_file(oid, "ladybird")
    parsed_ladybird_file = JSON.parse(ladybird_file)
    parsed_ladybird_file["orbisBarcode"]
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

  def get_fixture_file(oid, metadata_source)
    fixture_file_folder = Rails.root.join("spec", "fixtures", metadata_source)
    file_prefix = file_prefix(metadata_source)
    file_path = fixture_file_folder.join("#{file_prefix}#{oid}" + ".json")
    File.read(file_path) if File.exist?(file_path)
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
