# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "Solr Indexing Tasks", type: :system do
  describe 'Click solr task button' do
    before do
      visit management_index_path
      click_on("Index to Solr")
    end

    it 'displays a flash message that indexing is occuring in the background' do
      expect(page.status_code).to eq(200)
      expect(page).to have_content(/These files are being indexed in the background and will be ready soon./)
    end

    it "can index the contents of a directory to Solr" do
      response = SolrService.connection.get 'select', params: { q: '*:*' }
      expect(response["response"]["numFound"]).to be > 45
      expect(response["response"]["numFound"]).to be < 101
    end
  end
end
