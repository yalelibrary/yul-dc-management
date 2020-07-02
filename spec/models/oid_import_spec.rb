# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OidImport, type: :model do
  describe "csv file import" do
    let!(:csv_file) { File.new(fixture_path + '/short_fixture_ids.csv') }

    it "is valid with valid attributes" do
      expect(OidImport.new).to be_valid
    end

    it "is valid with valid attribute" do
      subject { File.new(fixture_path + '/short_fixture_ids.csv') }
      expect(subject).to be_valid
    end

    it "is valid with valid attribute" do
      subject { File.new(fixture_path + '/short_fixture_ids.pdf') }
      expect(subject.id).to eq nil
    end

  end
end
