# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "Management", type: :feature do
  describe 'index page' do
    before do
      ENV['REGISTRY_URI'] = 'yalelibraryit/dc-management'
      ENV['MANAGEMENT_TAG'] = 'v1beta.gamma'
      ENV['SOLR_TAG'] = 'v3alpha.omega'
      visit management_index_path
    end

    it 'dynamically displays deployed services' do
      expect(page).to have_content("Containers")
      expect(page).to have_content("yalelibraryit/dc-management:v1beta.gamma")
      expect(page).to have_content("postgres")
      expect(page).to have_content("yalelibraryit/dc-solr:v3alpha.omega")
    end
  end
end
