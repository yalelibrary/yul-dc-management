# frozen_string_literal: true

class ActivityStreamReader
  def self.update; end

  ##
  # Return the last time the Activity Stream was successfully read
  def last_run_time
    last_success = ActivityStreamLog.where(status: "Success").last
    last_success.run_time
  end

  def walk_the_stream(_last_run_time)
    mcs = MetadataCloudService.new
    latest_page = mcs.mc_get("https://metadata-api-test.library.yale.edu/metadatacloud/streams/activity").body.to_s
    parsed_page = JSON.parse(latest_page)
    parsed_page["orderedItems"].first["endTime"] # most_recent_in_stream
  end
end
