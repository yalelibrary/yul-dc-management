# frozen_string_literal: true
require 'rails_helper'
WebMock.allow_net_connect!

RSpec.describe "Metadata Sample tasks", type: :system, clean: true do
  describe 'Click create metadata sample' do
    before do
      visit new_metadata_sample_path
      select('Ladybird')
      fill_in('Number of samples', with: 2)
      click_on("Create Metadata sample")
    end

    it "runs the metadata sampling service" do
      expect(SampleField.count).to be > 5
      expect(MetadataSample.last.seconds_elapsed).to be > 0
    end

    it "displays the fields related to that Metadata Sample" do
      expect(page.body).to include "Sample fields"
    end

    it "can delete a sample" do
      visit metadata_samples_path
      click_on("Destroy")
    end
  end
end
