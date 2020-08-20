# frozen_string_literal: true
require "rails_helper"
require "support/time_helpers"

RSpec.describe ActivityStreamReader, prep_metadata_sources: true do
  let(:asr) { described_class.new }
  let(:relevant_parent_object) do
    FactoryBot.create(
      :parent_object_with_bib,
      oid: "2004628",
      bib: "3163155",
      last_ladybird_update: "2020-06-10 17:38:27".to_datetime,
      last_voyager_update: "2020-06-10 17:38:27".to_datetime
    )
  end
  let(:dependent_object_ladybird) do
    FactoryBot.create(
      :dependent_object,
      parent_object_id: "2004628",
      metadata_source: "ladybird",
      dependent_uri: "/ladybird/oid/2004628"
    )
  end
  let(:dependent_object_voyager_bib) do
    FactoryBot.create(
      :dependent_object,
      parent_object_id: "2004628",
      metadata_source: "ils",
      dependent_uri: "/ils/bib/3163155"
    )
  end
  let(:dependent_object_voyager_holding) do
    FactoryBot.create(
      :dependent_object,
      parent_object_id: "16685691",
      metadata_source: "ils",
      dependent_uri: "/ils/holding/13895201"
    )
  end
  let(:dependent_object_voyager_item) do
    FactoryBot.create(
      :dependent_object,
      parent_object_id: "16685691",
      metadata_source: "ils",
      dependent_uri: "/ils/item/12140816"
    )
  end
  let(:relevant_parent_object_two) do
    FactoryBot.create(
      :parent_object_with_bib,
      oid: "16685691",
      bib: "13881242",
      holding: "13895201",
      item: "12140816",
      barcode: "39002131329220",
      last_ladybird_update: "2020-06-10 17:38:27".to_datetime,
      last_voyager_update: "2020-06-10 17:38:27".to_datetime
    )
  end
  let(:dependent_object_ladybird_two) do
    FactoryBot.create(
      :dependent_object,
      parent_object_id: "16685691",
      metadata_source: "ladybird",
      dependent_uri: "/ladybird/oid/16685691"
    )
  end
  let(:parent_object_with_aspace_uri) do
    FactoryBot.create(
      :parent_object_with_aspace_uri,
      oid: "16854285",
      bib: "12307100",
      barcode: "39002102340669",
      aspace_uri: "/repositories/11/archival_objects/515305",
      last_aspace_update: "2020-06-10 17:38:27".to_datetime
    )
  end
  let(:dependent_object_aspace_repository) do
    FactoryBot.create(
      :dependent_object,
      parent_object_id: "16854285",
      metadata_source: "aspace",
      dependent_uri: "/aspace/repositories/11/archival_objects/515305"
    )
  end
  let(:dependent_object_aspace_agent) do
    FactoryBot.create(
      :dependent_object,
      parent_object_id: "16854285",
      metadata_source: "aspace",
      dependent_uri: "/aspace/agents/corporate_entities/2251"
    )
  end

  let(:relevant_oid) { "2004628" }
  let(:irrelevant_oid) { "not_in_db" }
  let(:relevant_time) { "2020-06-12T21:06:53.000+0000" }
  let(:irrelevant_time) { "2020-06-12T21:04:53.000+0000" }
  let(:relevant_activity_type) { "Update" }
  let(:irrelevant_activity_type) { "Create" }
  let(:relevant_item_from_ladybird) do
    {
      "endTime" => relevant_time,
      "object" => {
        "id" => "http://#{MetadataCloudService.metadata_cloud_host}/metadatacloud/api/ladybird/oid/2004628",
        "type" => "Document"
      },
      "type" => relevant_activity_type
    }
  end
  let(:relevant_item_two) do
    {
      "endTime" => relevant_time,
      "object" => {
        "id" => "http://#{MetadataCloudService.metadata_cloud_host}/metadatacloud/api/ladybird/oid/16685691",
        "type" => "Document"
      },
      "type" => relevant_activity_type
    }
  end
  let(:relevant_item_from_voyager) do
    {
      "endTime" => relevant_time,
      "object" => {
        "id" => "http://#{MetadataCloudService.metadata_cloud_host}/metadatacloud/api/ils/bib/3163155",
        "type" => "Document"
      },
      "type" => relevant_activity_type
    }
  end
  let(:relevant_item_from_voyager_holding) do
    {
      "endTime" => relevant_time,
      "object" => {
        "id" => "http://#{MetadataCloudService.metadata_cloud_host}/metadatacloud/api/ils/holding/10050400",
        "type" => "Document"
      },
      "type" => relevant_activity_type
    }
  end
  let(:relevant_item_from_voyager_item) do
    {
      "endTime" => relevant_time,
      "object" => {
        "id" => "http://#{MetadataCloudService.metadata_cloud_host}/metadatacloud/api/ils/item/10763785",
        "type" => "Document"
      },
      "type" => relevant_activity_type
    }
  end
  let(:relevant_item_from_aspace) do
    {
      "endTime" => relevant_time,
      "object" => {
        "id" => "http://#{MetadataCloudService.metadata_cloud_host}/metadatacloud/api/aspace/repositories/11/archival_objects/515305",
        "type" => "Document"
      },
      "type" => relevant_activity_type
    }
  end
  let(:relevant_item_from_aspace_dependent_uri) do
    {
      "endTime" => relevant_time,
      "object" => {
        "id" => "http://#{MetadataCloudService.metadata_cloud_host}/metadatacloud/api/aspace/agents/corporate_entities/2251",
        "type" => "Document"
      },
      "type" => relevant_activity_type
    }
  end
  let(:irrelevant_item_not_in_db) do
    {
      "endTime" => relevant_time,
      "object" => {
        "id" => "http://#{MetadataCloudService.metadata_cloud_host}/metadatacloud/api/ladybird/oid/#{irrelevant_oid}",
        "type" => "Document"
      },
      "type" => relevant_activity_type
    }
  end
  let(:irrelevant_item_too_old) do
    {
      "endTime" => irrelevant_time,
      "object" => {
        "id" => "http://#{MetadataCloudService.metadata_cloud_host}/metadatacloud/api/ladybird/oid/#{relevant_oid}",
        "type" => "Document"
      },
      "type" => relevant_activity_type
    }
  end
  let(:irrelevant_not_an_update) do
    {
      "endTime" => "2020-06-12T21:06:53.000+0000",
      "object" => {
        "id" => "http://#{MetadataCloudService.metadata_cloud_host}/metadatacloud/api/ladybird/oid/#{relevant_oid}",
        "type" => "Document"
      },
      "type" => irrelevant_activity_type
    }
  end

  let(:asl_old_success) { FactoryBot.create(:successful_activity_stream_log, run_time: "2020-06-12T21:05:53.000+0000".to_datetime) }

  before do
    # Part of ActiveSupport, see support/time_helpers.rb, behaves similarly to old TimeCop gem
    freeze_time
    # OID 2004628
    stub_metadata_cloud("2004628", "ladybird")
    stub_metadata_cloud("V-2004628", "ils")
    # OID 16685691
    stub_metadata_cloud("16685691", "ladybird")
    stub_metadata_cloud("V-16685691", "ils")
    # OID 16854285
    stub_metadata_cloud("16854285", "ladybird")
    stub_metadata_cloud("V-16854285", "ils")
    stub_metadata_cloud("AS-16854285", "aspace")
    # Activity Stream - stub requests to MetadataCloud activity stream with fixture objects that represent single activity_stream json pages
    stub_request(:get, "https://#{MetadataCloudService.metadata_cloud_host}/metadatacloud/streams/activity")
      .to_return(status: 200, body: File.open(File.join(fixture_path, "activity_stream", "page-3.json")).read)
    stub_request(:get, "https://#{MetadataCloudService.metadata_cloud_host}/metadatacloud/streams/activity/page-2")
      .to_return(status: 200, body: File.open(File.join(fixture_path, "activity_stream", "page-2.json")).read)
    stub_request(:get, "https://#{MetadataCloudService.metadata_cloud_host}/metadatacloud/streams/activity/page-1")
      .to_return(status: 200, body: File.open(File.join(fixture_path, "activity_stream", "page-1.json")).read)
    stub_request(:get, "https://#{MetadataCloudService.metadata_cloud_host}/metadatacloud/streams/activity/page-0")
      .to_return(status: 200, body: File.open(File.join(fixture_path, "activity_stream", "page-0.json")).read)
  end

  # There will be a automated job that fetches updates from the MetadataCloud on some configured schedule.
  # Each time the activity_stream_reader is run, it creates an activity_stream_log event, which records when it was run,
  # whether that run was successful, and how and many objects were referenced in that activity stream run.
  context "daily automated updates" do
    before do
      relevant_parent_object
      dependent_object_ladybird
      dependent_object_voyager_bib
      relevant_parent_object_two
      dependent_object_voyager_holding
      dependent_object_ladybird_two
      parent_object_with_aspace_uri
      dependent_object_aspace_repository
    end

    it "can get a page from the MetadataCloud activity stream" do
      expect(asr.fetch_and_parse_page("https://#{MetadataCloudService.metadata_cloud_host}/metadatacloud/streams/activity")["type"]).to eq "OrderedCollectionPage"
    end

    it "marks objects as updated in the database" do
      relevant_parent_object.last_ladybird_update = 2.days.ago
      ladybird_update_before = relevant_parent_object.last_ladybird_update
      relevant_parent_object.last_voyager_update = 3.days.ago
      voyager_update_before = relevant_parent_object.last_voyager_update
      parent_object_with_aspace_uri.last_aspace_update = 4.days.ago
      aspace_update_before = parent_object_with_aspace_uri.last_aspace_update
      described_class.update
      ladybird_update_after = ParentObject.find_by(oid: relevant_oid).last_ladybird_update
      voyager_update_after = ParentObject.find_by(oid: relevant_oid).last_voyager_update
      aspace_update_after = ParentObject.find_by(aspace_uri: "/repositories/11/archival_objects/515305").last_aspace_update
      expect(ladybird_update_before).to be < ladybird_update_after
      expect(voyager_update_before).to be < voyager_update_after
      expect(aspace_update_before).to be < aspace_update_after
    end

    # There are ~1837 total items from the relevant time period, but only 3 of them
    # are unique Ladybird, Voyager, or ArchiveSpace updates
    # with the oid that has been added to the database in our before block
    it "can process the partial activity stream if there is a previous successful run" do
      asl_old_success
      expect(ActivityStreamLog.count).to eq 1
      expect(ActivityStreamLog.last.retrieved_records).to eq asl_old_success.retrieved_records
      asr.process_activity_stream
      expect(ActivityStreamLog.count).to eq 2
      expect(ActivityStreamLog.last.retrieved_records).to eq 3
    end

    # There are ~4000 total items, but only 3 of them are unique Ladybird, Voyager,
    # or ArchiveSpace updates with the oid of the relevant_parent_object
    # that have been added to the database in our before block
    it "processes the entire activity stream if it has never been run before" do
      expect(ActivityStreamLog.count).to eq 0
      described_class.update
      expect(ActivityStreamLog.count).to eq 1
      expect(ActivityStreamLog.last.activity_stream_items).to be > 4000
      expect(ActivityStreamLog.last.retrieved_records).to eq 3
    end

    context "creates a set of remote_dependent_uris from activity stream entries" do
      it "adds relevant oids for update to an array" do
        expect(asr.remote_dependent_uris.size).to eq 0
        asr.process_item(relevant_item_from_ladybird)
        expect(asr.remote_dependent_uris.size).to eq 1
        asr.process_item(relevant_item_two)
        expect(asr.remote_dependent_uris.size).to eq 2
        asr.process_item(relevant_item_from_voyager)
        expect(asr.remote_dependent_uris.size).to eq 3
        expect(asr.remote_dependent_uris).not_to include nil
        expect(asr.remote_dependent_uris).to include "http://#{MetadataCloudService.metadata_cloud_host}/metadatacloud/api/ils/bib/3163155"
        asr.process_item(relevant_item_from_voyager_holding)
        expect(asr.remote_dependent_uris.size).to eq 4
        asr.process_item(relevant_item_from_aspace)
        expect(asr.remote_dependent_uris.size).to eq 5
      end
    end
  end

  context "determining whether an item from the activity stream is relevant" do
    let(:asl_old_success) do
      FactoryBot.create(
        :successful_activity_stream_log,
        run_time: "2020-06-12T21:05:53.000+0000".to_datetime
      )
    end

    it "can confirm that a Ladybird item is relevant" do
      relevant_parent_object
      dependent_object_ladybird
      expect(asr.relevant?(relevant_item_from_ladybird)).to be_truthy
    end

    it "can confirm that a Voyager item is relevant using bib id" do
      relevant_parent_object
      dependent_object_voyager_bib
      expect(asr.relevant?(relevant_item_from_voyager)).to be_truthy
    end

    it "can confirm that a Voyager item is relevant using item and holding ids" do
      relevant_parent_object_two
      dependent_object_voyager_holding
      dependent_object_voyager_item
      expect(asr.relevant?(relevant_item_from_voyager_holding)).to be_truthy
      expect(asr.relevant?(relevant_item_from_voyager_item)).to be_truthy
    end

    it "can confirm that an ArchiveSpace item is relevant" do
      parent_object_with_aspace_uri
      dependent_object_aspace_repository
      expect(asr.relevant?(relevant_item_from_aspace)).to be_truthy
    end

    it "can confirm that an ArchiveSpace item is relevant based on its dependent URI" do
      parent_object_with_aspace_uri
      dependent_object_aspace_agent
      expect(asr.relevant?(relevant_item_from_aspace_dependent_uri)).to be_truthy
    end

    it "does not confirm that an irrelevant item is relevant - not update" do
      expect(asr.relevant?(irrelevant_not_an_update)).to be_falsey
    end
  end

  context "getting the uri for the previous page" do
    let(:json_parsed_page) { JSON.parse(latest_activity_stream_page) }
    let(:latest_activity_stream_page) { File.open(File.join(fixture_path, "activity_stream", "page-3.json")).read }

    it "can get the uri for the previous page" do
      expect(asr.previous_page_link(json_parsed_page)).to eq "https://#{MetadataCloudService.metadata_cloud_host}/metadatacloud/streams/activity/page-2"
    end
  end

  it "has a tally_activity_stream_items of 0 when first initialized" do
    expect(asr.tally_activity_stream_items).to eq 0
  end

  context "determining the last successful run" do
    let(:asl_failed) { FactoryBot.create(:failed_activity_stream_log, run_time: 1.hour.ago) }
    let(:asl_new_success) { FactoryBot.create(:successful_activity_stream_log, run_time: 2.hours.ago) }

    it "can figure out the last time it was run successfully" do
      asl_new_success
      asl_failed
      expect(asr.last_run_time).to eq asl_new_success.run_time
    end
  end

  context "with multiple oids for a single dependent uri" do
    let(:parent_object_aspace_2) do
      FactoryBot.create(
        :parent_object_with_aspace_uri,
        oid: "12345",
        aspace_uri: "/repositories/11/archival_objects/515305",
        last_aspace_update: "2020-06-10 17:38:27".to_datetime
      )
    end
    let(:dependent_object_aspace_agent_2) do
      FactoryBot.create(
        :dependent_object,
        parent_object_id: "12345",
        metadata_source: "aspace",
        dependent_uri: "/aspace/agents/corporate_entities/2251"
      )
    end

    context "creating a set of dependent_uris from database" do
      it "creates a set of local dependent uris" do
        parent_object_with_aspace_uri
        relevant_parent_object
        relevant_parent_object_two
        expect(asr.local_dependent_uris).not_to be nil
        expect(asr.local_dependent_uris.class).to eq Set
        expect(asr.local_dependent_uris.count).to eq 16
        expect(asr.local_dependent_uris.include?("/ils/bib/3163155")).to be_truthy
      end
    end
  end
end
