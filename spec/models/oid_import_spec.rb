# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OidImport, type: :model do
  subject(:oid_import) { described_class.new }
  describe "csv file import" do
    it "requires no attributes" do
      expect(OidImport.new).to be_valid
    end

    it "accepts a csv file as a virtual attribute and read the csv into the csv property" do
      oid_import.file = File.new(fixture_path + '/short_fixture_ids.csv')
      expect(oid_import.csv).to be_present
      expect(oid_import).to be_valid
    end

    it "does not accept non csv files" do
      oid_import.file = File.new(Rails.root.join('public', 'favicon.ico'))
      expect(oid_import).not_to be_valid
      expect(oid_import.csv).to be_blank
    end
  end
end
