# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "Solr Indexing Tasks", type: :system, clean: true do
  describe 'Click Index to Solr button' do
    before do
      visit management_index_path
    end

    context "with a Voyager button press" do
      before do
        click_on("Index Voyager Records to Solr")
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

    context "with a Ladybird button press" do
      before do
        click_on("Index Ladybird Records to Solr")
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
end
