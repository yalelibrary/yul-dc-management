# frozen_string_literal: true

class ActivityStreamReader
  # This is the primary way that automated updates will happen.
  def self.update
    asr = ActivityStreamReader.new

    asr.walk_the_stream
  end

  ##
  # Return the last time the Activity Stream was successfully read
  # If the ActivityStreamReader has not yet successfully run (if the ActivityStreamLog is empty or does not have successes),
  # then the ActivityStreamReader should read through the entire activity stream from the MetadataCloud.
  def last_run_time
    @last_run_time ||= ActivityStreamLog.where(status: "Success").last&.run_time&.to_datetime
  end

  def walk_the_stream
    process_entire_activity_stream if last_run_time.nil?
  end

  def process_entire_activity_stream
    page = fetch_most_recent_page
    log = ActivityStreamLog.create(run_time: DateTime.current, status: "Running")
    tally = 0
    tally += page["orderedItems"].count
    previous_page_link = previous_page_link(page)
    process_page(previous_page_link)
    log.object_count = tally
    log.save
  end

  def fetch_most_recent_page
    mcs = MetadataCloudService.new
    latest_page = mcs.mc_get("https://metadata-api-test.library.yale.edu/metadatacloud/streams/activity").body.to_s
    JSON.parse(latest_page)
  end

  def fetch_and_process_page(page_url)
    mcs = MetadataCloudService.new
    latest_page = mcs.mc_get(page_url).body.to_s
    JSON.parse(latest_page)
  end

  ##
  # Takes a parsed json Activity Stream page and returns the link to the previous page
  def previous_page_link(page)
    http_url = page["prev"]["id"]
    http_url.gsub("http://", "https://")
  end

  def process_page(page_url)
    page = fetch_and_process_page(page_url)
    page["orderedItems"].count
    # while previous_page_link(page)
    #   puts page["id"]
    # end
  end
end
