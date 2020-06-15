# frozen_string_literal: true

class ActivityStreamReader
  # This is the primary way that automated updates will happen.
  def self.update
    asr = ActivityStreamReader.new
    asr.walk_the_stream
  end

  ##
  # Return the last time the Activity Stream was successfully read
  def last_run_time
    @last_run_time ||= ActivityStreamLog.where(status: "Success").last.run_time.to_datetime
  end

  def walk_the_stream
    parsed_page = fetch_page
    most_recent_in_stream = parsed_page["orderedItems"].first["endTime"].to_datetime
    if most_recent_in_stream.after?(last_run_time)
      # Make ActivityStreamEvents
      "foo"
    else
      # Stop or go to next event
      "bar"
    end
  end

  def fetch_page
    mcs = MetadataCloudService.new
    latest_page = mcs.mc_get("https://metadata-api-test.library.yale.edu/metadatacloud/streams/activity").body.to_s
    JSON.parse(latest_page)
  end
end
