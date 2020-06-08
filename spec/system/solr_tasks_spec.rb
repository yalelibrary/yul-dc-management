# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "Solr Indexing Tasks", type: :system do
  describe 'index' do
    it 'redirects to the run_task page' do
      visit management_index_path

      click_on("Index to Solr")
      expect(page.status_code).to eq(200)
      expect(page).to have_content(/Your files have been indexed/)
    end
  end
end
