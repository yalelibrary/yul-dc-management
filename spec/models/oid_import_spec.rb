require 'rails_helper'

RSpec.describe OidImport, type: :model do	

  describe "csv file import" do
    before do
      visit management_index_path
    end
    let!(:csv_file) { File.new(fixture_path + '/short_fixture_ids.csv') }
    it "can sucessfully import a csv file" do
      described_class.import(csv_file)
      expect(described_class.count).to eq(1)
    end
  end

end	