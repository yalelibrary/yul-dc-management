# frozen_string_literal: true

class MetadataCloudService
  ##
  # This is the method that is called from the yale:refresh_fixture_data rake task
  def self.refresh_fixture_data(oid_path, metadata_source)
    oids = MetadataCloudService.list_of_oids(oid_path)
    save_json_from_oids(oids, metadata_source)
  end

  def self.refresh_from_upload(csv, metadata_source)
    oids = csv.entries.map { |r| r['oid'] }
    save_json_from_oids(oids, metadata_source)
  end

  def self.save_json_from_oids(oids, metadata_source)
    oids.each do |oid|
      next unless MetadataCloudService.build_metadata_cloud_url(oid, metadata_source)
      metadata_cloud_url = MetadataCloudService.build_metadata_cloud_url(oid, metadata_source)
      full_response = MetadataCloudService.mc_get(metadata_cloud_url)
      next unless full_response.status == 200
      MetadataCloudService.save_mc_json_to_file(full_response, oid, metadata_source)
    end
  end

  ##
  # Takes a Metadata Cloud formatted url and returns the full HTTP response with headers
  def self.mc_get(mc_url)
    metadata_cloud_username = ENV["MC_USER"]
    metadata_cloud_password = ENV["MC_PW"]
    HTTP.basic_auth(user: metadata_cloud_username, pass: metadata_cloud_password).get(mc_url)
  end

  ##
  # Takes an oid (Ladybird identifier) and a metadata source (allowed values are ladybird, ils, and aspace), and returns
  # the appropriate URL to pull the metadata from the Yale Metadata Cloud
  def self.build_metadata_cloud_url(oid, metadata_source)
    if metadata_source == "ladybird"
      identifier_block = "/oid/#{oid}"
    elsif metadata_source == "ils"
      bib = MetadataCloudService.get_bib(oid)
      barcode = MetadataCloudService.get_barcode(oid)
      identifier_block = if barcode.nil?
                           "/bib/#{bib}"
                         else
                           "/barcode/#{barcode}?bib=#{bib}"
                         end
    elsif metadata_source == "aspace"
      return nil unless MetadataCloudService.get_archive_space_uri(oid)
      identifier_block = MetadataCloudService.get_archive_space_uri(oid)
    end
    "https://#{MetadataCloudService.metadata_cloud_host}/metadatacloud/api/#{metadata_source}#{identifier_block}"
  end

  def self.get_archive_space_uri(oid)
    ladybird_hash = FixtureParsingService.fixture_file_to_hash(oid, "ladybird")
    ladybird_hash["archiveSpaceUri"]
  end

  ##
  # Takes an oid and returns the corresponding bib, as defined by ladybird
  # I suspect this approach is going to be super slow, should probably decide how long we want to keep these and figure out
  # how we want to save them. Like, should refreshing the relationship between the Ladybird IDs and the bib ids be done on a chron job?
  def self.get_bib(oid)
    ladybird_hash = FixtureParsingService.fixture_file_to_hash(oid, "ladybird")
    ladybird_hash["orbisRecord"]
  end

  def self.get_barcode(oid)
    ladybird_hash = FixtureParsingService.fixture_file_to_hash(oid, "ladybird")
    ladybird_hash["orbisBarcode"]
  end

  ##
  # Takes a full HTTP response with headers and saves a json file
  def self.save_mc_json_to_file(mc_response, oid, metadata_source)
    file_folder = Rails.root.join("spec", "fixtures", metadata_source)
    raw_metadata = mc_response.body.to_str
    parsed_metadata = JSON.parse(raw_metadata)
    file_prefix = FixtureParsingService.file_prefix(metadata_source)

    File.write(file_folder.join("#{file_prefix}#{oid}" + ".json"), JSON.pretty_generate(parsed_metadata))
  end

  ##
  # Takes a csv file
  def self.list_of_oids(oid_path)
    @list_of_oids ||= FixtureParsingService.build_oid_array(oid_path)
  end

  def self.metadata_cloud_host
    "metadata-api-uat.library.yale.edu"
  end
end
