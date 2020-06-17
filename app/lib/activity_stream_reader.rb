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
      process_item(item) if last_run_time.nil? || item["endTime"].to_datetime.after?(last_run_time)
    end
    process_page(previous_page_link(page)) if previous_page_link(page)
  end

  def relevant?(_item)
    oid = _item[:object][:id].match(/\/api\/ladybird\/oid\/(\S*)/)
    byebug
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
