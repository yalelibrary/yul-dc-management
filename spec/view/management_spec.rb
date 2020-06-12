# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "Management", type: :feature do
  describe 'index page' do
    before do
      ENV['MANAGEMENT_VERSION'] = 'v1beta.gamma'
      ENV['POSTGRES_VERSION'] = 'SQLite'
      ENV['BLACKLIGHT_VERSION'] = 'v2.alpha.sigma'
      ENV['SOLR_VERSION'] = 'v3alpha.omega'
      ENV['IIIF_IMAGE_VERSION'] = 'v4delta.chi'
      ENV['IIIF_MANIFEST_VERSION'] = 'v5lambda.phi'
      visit management_index_path
    end

    it 'dynamically displays deployed services' do
      expect(page).to have_content("Containers")
      expect(page).to have_content("yalelibraryit/dc-management:v1beta.gamma")
      expect(page).to have_content("curationexperts/dc-postgres:SQLite")
      expect(page).to have_content("yalelibraryit/dc-blacklight:v2.alpha.sigma")
      expect(page).to have_content("yalelibraryit/dc-solr:v3alpha.omega")
      expect(page).to have_content("yalelibraryit/dc-iiif-cantaloupe:v4delta.chi")
      expect(page).to have_content("yalelibraryit/dc-management:v5lambda.phi")
    end
  end
end
