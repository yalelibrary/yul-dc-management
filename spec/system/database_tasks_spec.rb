# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "Database Tasks", type: :system do
  describe 'Click Seed Database button' do
    before do
      visit management_index_path
    end
    it "can update the database" do
      expect(ParentObject.count).to eq 0
      click_on("Update Database")
      expect(ParentObject.count).to be > 40
    end

    context "with Activity Stream requests" do
      let(:page_0_activity_stream_page) { File.open(File.join(fixture_path, "activity_stream", "page-0.json")).read }
      before do
        stub_request(:get, "https://metadata-api-test.library.yale.edu/metadatacloud/streams/activity")
          .to_return(status: 200, body: page_0_activity_stream_page)
      end
      it "can pull updates from the activity stream" do
        expect(ActivityStreamLog.count).to eq 0
        click_on("Update from Activity Stream")
        expect(ActivityStreamLog.count).to eq 1
      end
    end
  end
end
