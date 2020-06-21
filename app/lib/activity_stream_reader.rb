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

  ##
  # It takes the url for an Activity Stream page, tallies the number of items on that page,
  # and if there is a link to a previous page, recursively process that page as well, until all pages have been processed.
  def process_page(page_url)
    page = fetch_and_parse_page(page_url)
    page["orderedItems"].each do |item|
      process_item(item) if relevant?(item)
    end
    process_page(previous_page_link(page)) if previous_page_link(page)
  end

  ##
  # It takes an item from the activity stream and returns either true or false depending on whether that object
  # - Is in the database, based on its Ladybird OID (this will have to be extended for non-ladybird objects)
  # - Was updated within the timeframe we're interested in (either the entire activity stream if it has not been
  # previously successfully run, or after the last_run_time)
  # - Is an update (for now - will probably want to include deletions and creations in the future)
  def relevant?(item)
    return false unless item["type"] == "Update"
    return false unless last_run_time.nil? || item["endTime"].to_datetime.after?(last_run_time)
    return false unless find_by_id(item)
    true
  end

  def find_by_id(item)
    match_data = /\/api\/(\w*)\/(\w*)\/(\S*)/.match(item["object"]["id"])&.captures
    metadata_source = match_data[0]
    if metadata_source == "ladybird" || metadata_source == "ils"
      source_id_type = match_data[1]
      source_id = match_data[2]
      oid = ParentObject.where(source_id_type.to_s => source_id.to_s)&.first&.oid
      return false unless oid
    elsif metadata_source == "aspace"
      part_one = match_data[1]
      part_two = match_data[2]
      source_id = (part_one + "/" + part_two).to_s
      oid = ParentObject.where("aspace_uri" => source_id.to_s)&.first&.oid
      return false unless oid
    else
      return false
    end
    true
  end

  def process_item(item)
    @tally += 1
    oid = /\/api\/ladybird\/oid\/(\S*)/.match(item["object"]["id"])&.captures&.first
    return oids_for_update.add([oid, "ladybird"]) if oid
    bib = /\/api\/ils\/bib\/(\S*)/.match(item["object"]["id"])&.captures&.first
    if bib
      oid = ParentObject.find_by(bib: bib).oid
      return oids_for_update.add([oid, "ils"])
    end
  end

  # This set contains arrays, each of which contains the oid for the item that has been updated,
  # and the metadata_source that has been updated (Ladybird, Voyager ("ils"), or ArchiveSpace)
  # @example { ["2004628", "ladybird"], ["2004628", "ils"] }
  def oids_for_update
    @oids_for_update ||= Set.new
  end

  ##
  # Return the last time the Activity Stream was successfully read
  # If the ActivityStreamReader has not yet successfully run (if the ActivityStreamLog is empty or does not have successes),
  # then the ActivityStreamReader should read through the entire activity stream from the MetadataCloud.
  def last_run_time
    @last_run_time ||= ActivityStreamLog.where(status: "Success").last&.run_time&.to_datetime
  end

  def process_activity_stream
    log = ActivityStreamLog.create(run_time: DateTime.current, status: "Running")
    log.save
    process_page("https://metadata-api-test.library.yale.edu/metadatacloud/streams/activity")
    refresh_updated_items(oids_for_update)
    log.object_count = @tally
    log.status = "Success"
    log.save
  end

  def refresh_updated_items(oids_for_update)
    mcs = MetadataCloudService.new
    oids_for_update.each do |oid_array|
      oid = oid_array[0]
      metadata_source = oid_array[1]
      metadata_cloud_url = mcs.build_metadata_cloud_url(oid, metadata_source)
      full_response = mcs.mc_get(metadata_cloud_url)
      mcs.save_mc_json_to_file(full_response, oid, metadata_source)
      po = ParentObject.find_by(oid: oid)
      if metadata_source == "ladybird"
        po.last_ladybird_update = DateTime.current
      elsif metadata_source == "ils"
        po.last_voyager_update = DateTime.current
      end
      po.save
    end
  end

  def fetch_and_parse_page(page_url)
    mcs = MetadataCloudService.new
    latest_page = mcs.mc_get(page_url).body.to_s
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
