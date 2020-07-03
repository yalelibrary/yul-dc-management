# frozen_string_literal: true
require 'rails_helper'
WebMock.allow_net_connect!

RSpec.describe "Solr Indexing Tasks", type: :system, clean: true do
  describe 'Click Index to Solr button' do
    before do
      visit new_metadata_sample_path
      fill_in('Metadata source', with: 'ladybird')
      fill_in('Number of samples', with: 2)
      click_on("Create Metadata sample")
    end

    it "runs the metadata sampling service" do
      true
    end
  end
end
