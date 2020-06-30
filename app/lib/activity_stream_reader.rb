# frozen_string_literal: true

# An ActivityStreamReader reads json formatted activity stream documents from the MetadataCloud
class ActivityStreamReader
  attr_reader :tally

  # This is the primary way that automated updates will happen.
  def self.update
    asr = ActivityStreamReader.new
    asr.process_activity_stream
  end

  def initialize
    @tally = 0
  end

  # Logs and kicks off processing the activity stream from the MetadataCloud
  def process_activity_stream
    log = ActivityStreamLog.create(run_time: DateTime.current, status: "Running")
    log.save
    process_page("https://metadata-api-test.library.yale.edu/metadatacloud/streams/activity")
    refresh_updated_items(parent_objects_for_update)
    log.object_count = @tally
    log.status = "Success"
    log.save
  end

  ##
  # It takes the url for an Activity Stream page, and if there is a link to a previous page,
  # recursively processes that page as well, until all pages have been processed.
  def process_page(page_url)
    page = fetch_and_parse_page(page_url)
    page["orderedItems"].each do |item|
      process_item(item) if relevant?(item)
    end
    process_page(previous_page_link(page)) if previous_page_link(page)
  end

  def process_item(item)
    dependent_uri = parse_item_identifier(item)
    dependent_objects = dependent_objects_based_on(dependent_uri)
    return false unless dependent_objects
    add_to_parent_objects_for_update_set(dependent_objects)
    @tally += 1
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
  # Takes the dependent_uri of an item from the activity stream, matches it to DependentObjects
  # from the database, and returns those DependentObjects
  def dependent_objects_based_on(dependent_uri)
    dependent_objects = DependentObject.where(dependent_uri: dependent_uri)
    return false if dependent_objects.empty?
    dependent_objects
  end

  ##
  # Takes DependentObjects and adds an array containing each DependentObject's parent_object_id (the parent object's oid)
  # and metadata_source to the parent_objects_for_update set
  def add_to_parent_objects_for_update_set(dependent_objects)
    dependent_objects.each do |dep_obj|
      parent_objects_for_update.add([dep_obj.parent_object_id.to_s, dep_obj.metadata_source])
    end
  end

  ##
  # Takes an activity stream item and returns the item's unique identifier, matches the
  # "dependent_uri" for records from the MetadataCloud
  # @example
  #  "/ladybird/oid/2003431"
  def parse_item_identifier(item)
    item_id = item["object"]["id"]
    /\/api(\S*)/.match(item_id).captures.first
  end

  # This set contains arrays, each of which contains the oid for the item that has been updated,
  # and the metadata_source that has been updated (Ladybird, Voyager ("ils"), or ArchiveSpace)
  # @example { ["2004628", "ladybird"], ["2004628", "ils"] }
  def parent_objects_for_update
    @parent_objects_for_update ||= Set.new
  end

  ##
  # Return the last time the Activity Stream was successfully read
  # If the ActivityStreamReader has not yet successfully run (if the ActivityStreamLog is empty or does not have successes),
  # then the ActivityStreamReader should read through the entire activity stream from the MetadataCloud.
  def last_run_time
    @last_run_time ||= ActivityStreamLog.where(status: "Success").last&.run_time&.to_datetime
  end

  ##
  # Takes a set of arrays (see parent_objects_for_update), retrieves the appropriate record from the MetadataCloud,
  # and saves it to disk.
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
