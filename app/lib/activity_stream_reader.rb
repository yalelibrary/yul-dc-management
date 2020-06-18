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
    # byebug if item["object"]["id"] == "http://metadata-api-test.library.yale.edu/metadatacloud/api/ladybird/oid/2004628"
    return false unless item["type"] == "Update"
    return false unless last_run_time.nil? || item["endTime"].to_datetime.after?(last_run_time)
    oid = /\/api\/ladybird\/oid\/(\S*)/.match(item["object"]["id"])&.captures
    return false if oid.nil?
    return false unless ParentObject.find_by(oid: oid)
    true
  end

  def process_item(_item)
    @tally += 1
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
    log.object_count = @tally
    log.status = "Success"
    log.save
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
