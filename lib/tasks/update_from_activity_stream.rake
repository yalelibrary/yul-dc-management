# frozen_string_literal: true

namespace :yale do
  desc "Retrieve updated records based on the Activity Stream"
  task update_from_activity_stream: :environment do
    ActivityStreamReader.update!
    puts "update successful"
    puts "
    #{ActivityStreamLog.last.activity_stream_items} items in the Activity Stream,
    #{ActivityStreamLog.last.retrieved_records} records refreshed from metadata cloud
    "
  end
end
