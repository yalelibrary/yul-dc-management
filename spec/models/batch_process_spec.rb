require 'rails_helper'

RSpec.describe BatchProcess, type: :model, prep_metadata_sources: true do
  subject(:batch_process) { described_class.new }

  before do
    stub_metadata_cloud("2034600")
    stub_metadata_cloud("2046567")
    stub_metadata_cloud("16414889")
    stub_metadata_cloud("14716192")
    stub_metadata_cloud("16854285")
  end

  describe "csv file import" do
    it "requires no attributes" do
      expect(BatchProcess.new).to be_valid
    end

    it "accepts a csv file as a virtual attribute and read the csv into the csv property" do
      batch_process.file = File.new(fixture_path + '/short_fixture_ids.csv')
      expect(batch_process.csv).to be_present
      expect(batch_process).to be_valid
    end

    it "does not accept non csv files" do
      batch_process.file = File.new(Rails.root.join('public', 'favicon.ico'))
      expect(batch_process).not_to be_valid
      expect(batch_process.csv).to be_blank
    end

  end


end
