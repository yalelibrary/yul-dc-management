# frozen_string_literal: true
require "rails_helper"
require "support/time_helpers"

RSpec.describe ActivityStreamReader do
  let(:asr) { described_class.new }
  let(:asl_new_success) { FactoryBot.create(:successful_activity_stream_log, run_time: 2.hours.ago) }
  let(:relevant_parent_object) { FactoryBot.create(:parent_object_with_bib_id, oid: "2004628") }
  let(:asl_failed) { FactoryBot.create(:failed_activity_stream_log, run_time: 1.hour.ago) }
  let(:asl_old_success) { FactoryBot.create(:successful_activity_stream_log, run_time: "2020-06-12T21:05:53.000+0000".to_datetime) }
  let(:latest_activity_stream_page) { File.open(File.join(fixture_path, "activity_stream", "page-3.json")).read }
  let(:page_2_activity_stream_page) { File.open(File.join(fixture_path, "activity_stream", "page-2.json")).read }
  let(:page_1_activity_stream_page) { File.open(File.join(fixture_path, "activity_stream", "page-1.json")).read }
  let(:page_0_activity_stream_page) { File.open(File.join(fixture_path, "activity_stream", "page-0.json")).read }
  let(:json_parsed_page) { JSON.parse(latest_activity_stream_page) }

  before do
    # Part of ActiveSupport, see support/time_helpers.rb, behaves similarly to old TimeCop gem
    freeze_time
  end

  # There will be a automated job that fetches updates from the MetadataCloud on some configured schedule.
  # Each time the activity_stream_reader is run, it creates an activity_stream_log event, which records when it was run,
  # whether that run was successful, and how and many objects were referenced in that activity stream run.
  context "daily automated updates" do
    before do
      relevant_parent_object
      # Stub requests to MetadataCloud activity stream with fixture objects that represent single activity_stream json pages
      stub_request(:get, "https://metadata-api-test.library.yale.edu/metadatacloud/streams/activity")
        .to_return(status: 200, body: latest_activity_stream_page)
      stub_request(:get, "https://metadata-api-test.library.yale.edu/metadatacloud/streams/activity/page-2")
        .to_return(status: 200, body: page_2_activity_stream_page)
      stub_request(:get, "https://metadata-api-test.library.yale.edu/metadatacloud/streams/activity/page-1")
        .to_return(status: 200, body: page_1_activity_stream_page)
      stub_request(:get, "https://metadata-api-test.library.yale.edu/metadatacloud/streams/activity/page-0")
        .to_return(status: 200, body: page_0_activity_stream_page)
    end

    it "can get a page from the MetadataCloud activity stream" do
      expect(asr.fetch_and_parse_page("https://metadata-api-test.library.yale.edu/metadatacloud/streams/activity")["type"]).to eq "OrderedCollectionPage"
    end
    # There are 4000 total items, but only 4 of them are Ladybird updates with the oid of the relevant_parent_object
    # that has been added to the database in our before block
    it "processes the entire activity stream if it has never been run before" do
      expect(ActivityStreamLog.count).to eq 0
      described_class.update
      expect(ActivityStreamLog.count).to eq 1
      expect(ActivityStreamLog.last.object_count).to eq 4
    end
    # There are 1837 total items from the relevant time period, but only 2 of them are Ladybird updates
    # with the oid of the relevant_parent_object that has been added to the database in our before block
    it "can process the partial activity stream if there is a previous successful run" do
      asl_old_success
      expect(ActivityStreamLog.count).to eq 1
      expect(ActivityStreamLog.last.object_count).to eq asl_old_success.object_count
      asr.process_activity_stream
      expect(ActivityStreamLog.count).to eq 2
      expect(ActivityStreamLog.last.object_count).to eq 2
    end
  end

  context "determining whether an item from the activity stream is relevant" do
    let(:relevant_oid) { "2004628" }
    let(:irrelevant_oid) { "not_in_db" }
    # This is likely to change very soon
    let(:relevant_metadata_source) { "/ladybird/oid" }
    let(:irrelevant_metadata_source) { "/ils/bib" }
    let(:relevant_time) { "2020-06-12T21:06:53.000+0000" }
    let(:irrelevant_time) { "2020-06-12T21:04:53.000+0000" }
    let(:relevant_activity_type) { "Update" }
    let(:irrelevant_activity_type) { "Create" }
    let(:relevant_item) do
      {
        "endTime" => relevant_time,
        "object" => {
          "id" => "http://metadata-api-test.library.yale.edu/metadatacloud/api#{relevant_metadata_source}/#{relevant_oid}",
          "type" => "Document"
        },
        "type" => relevant_activity_type
      }
    end
    let(:irrelevant_item_not_ladybird) do
      {
        "endTime" => relevant_time,
        "object" => {
          "id" => "http://metadata-api-test.library.yale.edu/metadatacloud/api#{irrelevant_metadata_source}/#{relevant_oid}",
          "type" => "Document"
        },
        "type" => relevant_activity_type
      }
    end
    let(:irrelevant_item_not_in_db) do
      {
        "endTime" => relevant_time,
        "object" => {
          "id" => "http://metadata-api-test.library.yale.edu/metadatacloud/api#{relevant_metadata_source}/#{irrelevant_oid}",
          "type" => "Document"
        },
        "type" => relevant_activity_type
      }
    end
    let(:irrelevant_item_too_old) do
      {
        "endTime" => irrelevant_time,
        "object" => {
          "id" => "http://metadata-api-test.library.yale.edu/metadatacloud/api#{relevant_metadata_source}/#{relevant_oid}",
          "type" => "Document"
        },
        "type" => relevant_activity_type
      }
    end
    let(:irrelevant_not_an_update) do
      {
        "endTime" => "2020-06-12T21:06:53.000+0000",
        "object" => {
          "id" => "http://metadata-api-test.library.yale.edu/metadatacloud/api#{relevant_metadata_source}/#{relevant_oid}",
          "type" => "Document"
        },
        "type" => irrelevant_activity_type
      }
    end

    before do
      relevant_parent_object
      asl_old_success
    end

    it "can confirm that an item is relevant" do
      expect(asr.relevant?(relevant_item)).to be_truthy
    end

    it "does not confirm that an irrelevant item is relevant" do
      expect(asr.relevant?(irrelevant_item_not_ladybird)).to be_falsey
      expect(asr.relevant?(irrelevant_item_not_in_db)).to be_falsey
      expect(asr.relevant?(irrelevant_item_too_old)).to be_falsey
      expect(asr.relevant?(irrelevant_not_an_update)).to be_falsey
    end
  end

  it "can get the uri for the previous page" do
    expect(asr.previous_page_link(json_parsed_page)).to eq "https://metadata-api-test.library.yale.edu/metadatacloud/streams/activity/page-2"
  end

  it "has a tally of 0 when first initialized" do
    expect(asr.tally).to eq 0
  end

  it "can figure out the last time it was run successfully" do
    asl_new_success
    asl_failed
    expect(asr.last_run_time).to eq asl_new_success.run_time
  end
end
