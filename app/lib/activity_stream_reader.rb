# frozen_string_literal: true

# An ActivityStreamReader reads json formatted activity stream documents from the MetadataCloud
class ActivityStreamReader
  attr_reader :tally_activity_stream_items, :tally_retrieved_records

  # This is the primary way that automated updates will happen.
  def self.update
    asr = ActivityStreamReader.new
    asr.process_activity_stream
  end

  def initialize
    @tally_activity_stream_items = 0
    @tally_retrieved_records = 0
  end

  # Logs and kicks off processing the activity stream from the MetadataCloud
  def process_activity_stream
    log = ActivityStreamLog.create(run_time: DateTime.current, status: "Running")
    log.save
    process_page("https://metadata-api-test.library.yale.edu/metadatacloud/streams/activity")
    common_uris = intersection_of_dependent_uris(remote_dependent_uris, local_dependent_uris)
    parent_objects_for_update = items_for_update_from_dependent_uris(common_uris)
    refresh_updated_items(parent_objects_for_update)
    log.activity_stream_items = @tally_activity_stream_items
    log.retrieved_records = @tally_retrieved_records
    log.status = "Success"
    log.save
  end

  ##
  # It takes the url for an Activity Stream page, and if there is a link to a previous page,
  # recursively processes that page as well, until all pages have been processed.
  def process_page(page_url)
    page = fetch_and_parse_page(page_url)
    page["orderedItems"].last["endTime"]
    page["orderedItems"].each do |item|
      @tally_activity_stream_items += 1
      process_item(item) if relevant?(item)
    end

    process_page(previous_page_link(page)) if previous_page_link(page)
  end

  ##
  # Adds the item's uri to the array of remote_dependent_uris, for later comparison to the set of local_dependent_uris
  def process_item(item)
    remote_dependent_uris.push(item["object"]["id"])
  end

  ##
  # It takes an item from the activity stream and returns either true or false depending on whether that object
  # - Is an update
  # - Was updated within the timeframe we're interested in
  # (either the entire activity stream if it has not been
  # previously successfully run, or after the last_run_time)
  def relevant?(item)
    return false unless item["type"] == "Update"
    return false unless last_run_time.nil? || item["endTime"].to_datetime.after?(last_run_time)
    true
  end

  ##
  # Return the last time the Activity Stream was successfully read
  # If the ActivityStreamReader has not yet successfully run (if the ActivityStreamLog is empty or does not have successes),
  # then the ActivityStreamReader should read through the entire activity stream from the MetadataCloud.
  def last_run_time
    @last_run_time ||= ActivityStreamLog.where(status: "Success").last&.run_time&.to_datetime
  end

  def local_dependent_uris
    @local_dependent_uris ||= build_local_dependent_uri_set
  end

  ##
  # Ensures that the existing dependent URIs from the fixture objects have been updated in the database
  def update_local_dependent_uris
    FixtureParsingService.find_dependent_uris("aspace")
    FixtureParsingService.find_dependent_uris("ladybird")
    FixtureParsingService.find_dependent_uris("ils")
  end

  ##
  # Creates a set of all the dependent uris in the database for later comparison with the dependent_uris from the activity stream
  def build_local_dependent_uri_set
    update_local_dependent_uris
    dependent_uri_array = DependentObject.all.map(&:dependent_uri)
    dependent_uri_array.to_set
  end

  def remote_dependent_uris
    @remote_dependent_uris ||= []
  end

  ##
  # Takes the array of remote_dependent_uris and the set of local_dependent_uris and returns a Set that
  # is the intersection of local and remote dependent uris - that is, the uris of objects we want to update
  # from the MetadataCloud.
  def intersection_of_dependent_uris(remote_dependent_uris, local_dependent_uris)
    remote_dependent_uris_short = remote_dependent_uris.map { |uri| /\/api(\S*)/.match(uri).captures.first }
    remote_dependent_uris_short.to_set.intersection local_dependent_uris
  end

  ##
  # Takes the Set of dependent_uris that we are interested in refreshing (those that appear in the Activity Stream and
  # are in our local database), and returns a set containing the oid and metadata_source needed for the object's record
  # to be retrieved from the MetadataCloud.
  # @example
  #  { ["2004628", "ladybird"], ["2004628", "ils"] }
  def items_for_update_from_dependent_uris(common_uris)
    dependent_objects = common_uris.map { |uri| DependentObject.find_by(dependent_uri: uri) }
    parent_objects_for_update = dependent_objects.map { |depobj| [depobj.parent_object_id, depobj.metadata_source] }
    parent_objects_for_update.to_set
  end

  ##
  # Takes an activity stream item url and returns the item's unique identifier, matches the
  # "dependent_uri" for records from the MetadataCloud
  # @example
  #  "/ladybird/oid/2003431"
  def parse_item_identifier(item_url)
    /\/api(\S*)/.match(item_url).captures.first
  end

  ##
  # Takes a set of arrays (see tems_for_update_from_dependent_uris(common_uris) for example), retrieves the appropriate record from
  # the MetadataCloud, and saves it to disk.
  def refresh_updated_items(parent_objects_for_update)
    parent_objects_for_update.each do |parent_object_array|
      oid = parent_object_array[0]
      metadata_source = parent_object_array[1]
      metadata_cloud_url = MetadataCloudService.build_metadata_cloud_url(oid, metadata_source)
      full_response = MetadataCloudService.mc_get(metadata_cloud_url)
      MetadataCloudService.save_mc_json_to_file(full_response, oid, metadata_source)
      po = ParentObject.find_by(oid: oid)
      if metadata_source == "ladybird"
        po.last_ladybird_update = DateTime.current
      elsif metadata_source == "ils"
        po.last_voyager_update = DateTime.current
      elsif metadata_source == "aspace"
        po.last_aspace_update = DateTime.current
      end
      po.save
      @tally_retrieved_records += 1
    end
  end

  ##
  # Takes a MetadataCloud url as a string and returns a parsed JSON object
  # containing the body of the response
  def fetch_and_parse_page(page_url)
    latest_page = MetadataCloudService.mc_get(page_url).body.to_s
    JSON.parse(latest_page)
  end

  ##
  # Takes a parsed json Activity Stream page and returns the link to the previous page
  def previous_page_link(page)
    http_url = page["prev"]["id"]
    http_url.gsub("http://", "https://")
  rescue
    false
  end
end
