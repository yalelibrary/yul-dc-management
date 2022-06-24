# frozen_string_literal: true

# An ActivityStreamReader reads json formatted activity stream documents from the MetadataCloud
# rubocop:disable Metrics/ClassLength
class ActivityStreamReader
  attr_reader :tally_activity_stream_items, :tally_queued_records

  # This is the primary way that automated updates will happen.
  def self.update
    asr = ActivityStreamReader.new
    asr.process_activity_stream
  end

  def initialize
    @tally_activity_stream_items = 0
    @tally_queued_records = 0
    @parent_object_refs = Set.new
  end

  # Logs and kicks off processing the activity stream from the MetadataCloud
  # rubocop:disable Metrics/MethodLength
  def process_activity_stream
    @updated_uris = []
    @most_recent_update = nil
    @log = ActivityStreamLog.create(status: "Running")
    @log.save
    begin
      # recursively look at activity stream and add to parent_object_refs
      process_recursive("https://#{MetadataSource.metadata_cloud_host}/metadatacloud/streams/activity")
      refresh_updated_items(parent_object_refs)
      return unless @most_recent_update
      @log.run_time = @most_recent_update
      @log.activity_stream_items = @tally_activity_stream_items
      @log.retrieved_records = @tally_queued_records
    rescue => e
      @log.status = "Failed: #{e}"
    rescue SignalException => sigterm
      @log.status = "Terminated: #{sigterm}"
      @log.save
      raise sigterm
    else
      @log.status = "Success"
    end
    @log.save
  end
  # rubocop:enable Metrics/MethodLength

  ##
  # It takes the url for an Activity Stream page, and if there is a link to a previous page,
  # recursively processes that page as well, until all pages have been processed.
  def process_recursive(page_url)
    page = fetch_and_parse_page(page_url)
    page["orderedItems"].each do |item|
      @most_recent_update = item["endTime"] if @most_recent_update.nil?
      @tally_activity_stream_items += 1
      process_item(item) if relevant?(item)
    end
    earliest_item_on_page = page["orderedItems"].last["endTime"].to_datetime
    @parent_object_refs += parents_for_update_from_dependent_uris(updated_uris)
    @updated_uris = []
    @update_time_uri_map = {}
    @log.activity_stream_items = @tally_activity_stream_items
    @log.retrieved_records = @tally_queued_records
    @log.save
    Rails.logger.info("Processed activity stream page back to #{earliest_item_on_page}")
    process_recursive(previous_page_link(page)) if (previous_page_link(page) && last_run_time.nil?) || (previous_page_link(page) && earliest_item_on_page.after?(last_run_time))
  end

  ##
  # Adds the item's uri to the array of updated_uris, for later comparison to the set of local_dependent_uris
  def process_item(item)
    uri = item["object"]["id"].match(/.*\/api(.*)/)[1] # strip everything from the URL except after /api
    updated_uris.push(uri)
    update_time_uri_map[uri] = item["endTime"]
  end

  ##
  # It takes an item from the activity stream and returns either true or false depending on whether that object is an update or deleted
  def relevant?(item)
    # Don't process changes which occur after last_run_time
    return false unless (item["type"] == "Update" || item["type"] == "Delete") && (item['endTime'].to_datetime.after?(last_run_time) || item['endTime'].to_datetime == last_run_time)
    true
  end

  ##
  # Return the last time the Activity Stream was successfully read
  # If the ActivityStreamReader has not yet successfully run (if the ActivityStreamLog is empty or does not have successes),
  # then the ActivityStreamReader starts at the current time.
  def last_run_time
    @last_run_time ||= ActivityStreamLog.where(status: "Success").last&.run_time&.to_datetime || Time.current
  end

  def updated_uris
    @updated_uris ||= []
  end

  def update_time_uri_map
    @update_time_uri_map ||= {}
  end

  def update_time_oid_map
    @update_time_oid_map ||= {}
  end

  attr_reader :parent_object_refs

  def parents_for_update_from_dependent_uris(updated_uris)
    # See: https://guides.rubyonrails.org/active_record_querying.html#subset-conditions
    dependent_objects = DependentObject.where(dependent_uri: updated_uris)
    parent_object_refs_list = dependent_objects.map do |depobj|
      update_time_oid_map[depobj.parent_object_id] = update_time_uri_map[depobj.dependent_uri] unless update_time_uri_map[depobj.dependent_uri].nil?
      [depobj.parent_object_id, depobj.metadata_source]
    end
    parent_object_refs_list.to_set
  end

  ##
  # Takes a set of parent object refs, sets up a batch job, and queues a SetupMetadataJob
  def refresh_updated_items(parent_object_refs)
    #  Create a single batch for this update
    parent_object_refs.each do |parent_object_array|
      oid = parent_object_array[0]
      metadata_source = parent_object_array[1]
      # skip ladybird updates
      next if metadata_source == "ladybird"

      po = ParentObject.find_by_oid(oid)
      # skip it if the metadata source does not match (This should never happen after dependent uris are updating properly)
      next unless po&.authoritative_metadata_source&.metadata_cloud_name == metadata_source

      #  if po was updated after the most recent update of one of all the dependent uris, skip it
      last_update = metadata_source == 'aspace' ? po.last_aspace_update : po.last_voyager_update
      most_recent_dependend_object_update = update_time_oid_map[oid]
      next if last_update&.after?(most_recent_dependend_object_update)

      #  if po has a Metadata Job queued or in progress, skip it.
      next unless po.setup_metadata_jobs.empty?

      queue_parent_object(po)
      @tally_queued_records += 1
    end
  end

  def batch_process
    @batch_process ||= BatchProcess.create!(batch_action: 'activity stream updates', user: User.system_user)
  end

  def queue_parent_object(po)
    po.metadata_update = true
    po.current_batch_connection = batch_process.batch_connections.build(connectable: po)
    batch_process.save
    po.current_batch_process = batch_process
    po.save! # save will cause SetupMetadataJob to be queued since metadata_update is true.
  end

  ##
  # Takes a MetadataCloud url as a string and returns a parsed JSON object
  # containing the body of the response
  def fetch_and_parse_page(page_url)
    latest_page = MetadataSource.new.mc_get(page_url).body.to_s
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
# rubocop:enable Metrics/ClassLength
