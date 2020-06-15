# frozen_string_literal: true
require "rails_helper"
require "support/time_helpers"
WebMock.allow_net_connect!

RSpec.describe ActivityStreamReader do
  let(:asr) { described_class.new }
  let(:asl_new_success) { FactoryBot.create(:successful_activity_stream_log, run_time: 2.hours.ago) }
  let(:asl_failed) { FactoryBot.create(:failed_activity_stream_log, run_time: 1.hour.ago) }
  let(:latest_activity_stream_page) { File.open(File.join(fixture_path, "activity_stream", "page-3.json")).read }
  let(:json_parsed_page) { JSON.parse(latest_activity_stream_page) }

  # before do
  #   freeze_time
  #   # Apparently the mocked authorization hash matters in passing CI, so you have
  #   # to provide username and password matching the mocked stub request authorization
  #   @old_mc_user = ENV["MC_USER"]
  #   @old_mc_pw = ENV["MC_PW"]
  #   ENV["MC_USER"] = "some_username"
  #   ENV["MC_PW"] = "some_password"
  #   stub_request(:get, "https://metadata-api-test.library.yale.edu/metadatacloud/streams/activity")
  #     .with(
  #       headers: {
  #         'Authorization' => 'Basic c29tZV91c2VybmFtZTpzb21lX3Bhc3N3b3Jk',
  #         'Connection' => 'close',
  #         'Host' => 'metadata-api-test.library.yale.edu',
  #         'User-Agent' => 'http.rb/4.4.1'
  #       }
  #     )
  #     .to_return(status: 200, body: latest_activity_stream_page, headers: {})
  # end

  # after do
  #   ENV["MC_USER"] = @old_mc_user
  #   ENV["MC_PW"] = @old_mc_pw
  # end

  # There will be a automated job that fetches updates from the MetadataCloud on some configured schedule.
  # Each time the activity_stream_reader is run, it creates an activity_stream_log event, which records when it was run,
  # whether that run was successful, and how and many objects were referenced in that activity stream run.
  context "daily automated updates" do
    it "processes the entire activity stream if it has never been run before" do
      expect(ActivityStreamLog.count).to eq 0
      described_class.update
      expect(ActivityStreamLog.count).to eq 1
      expect(ActivityStreamLog.last.object_count).to eq 4000
    end

    # it "can call for updates" do
    #   expect(ActivityStreamLog.count).to eq 1
    #   described_class.update
    #   expect(ActivityStreamLog.count).to eq 2
    # end
  end

  it "can get the uri for the previous page" do
    expect(asr.previous_page_link(json_parsed_page)).to eq "https://metadata-api-test.library.yale.edu/metadatacloud/streams/activity/page-2"
  end

  it "can figure out the last time it was run successfully" do
    asl_new_success
    asl_failed
    expect(asr.last_run_time).to eq asl_new_success.run_time
  end

  context "with a last successful run older than the the fixture activity stream" do
    let(:asl_old_success) { FactoryBot.create(:successful_activity_stream_log, run_time: DateTime.new(2020, 6, 10).in_time_zone) }

    it "determines whether there is new information since the last run" do
      asl_old_success
      expect(asr.walk_the_stream).to eq "foo"
    end

    it "can pull data from the MetadataCloud activity stream" do
      asl_new_success
      expect(asr.walk_the_stream).to eq "bar"
    end
  end

  it "can get a page from the MetadataCloud activity stream" do
    expect(asr.fetch_page["type"]).to eq "OrderedCollectionPage"
  end
end
