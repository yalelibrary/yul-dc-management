# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "Management", type: :feature do
  describe 'index page' do
    around do |example|
      original_management_version = ENV['MANAGEMENT_VERSION']
      original_postgres_version = ENV['POSTGRES_VERSION']
      original_blacklight_version = ENV['BLACKLIGHT_VERSION']
      original_solr_version = ENV['SOLR_VERSION']
      original_iiif_image_version = ENV['IIIF_IMAGE_VERSION']
      original_iiif_manifest_version = ENV['IIIF_MANIFEST_VERSION']
      original_camerata_version = ENV['CAMERATA_VERSION']
      ENV['MANAGEMENT_VERSION'] = 'v1.beta.gamma'
      ENV['POSTGRES_VERSION'] = 'v7.delta.omicron'
      ENV['BLACKLIGHT_VERSION'] = 'v2.alpha.sigma'
      ENV['SOLR_VERSION'] = 'v3.alpha.omega'
      ENV['IIIF_IMAGE_VERSION'] = 'v4.delta.chi'
      ENV['IIIF_MANIFEST_VERSION'] = 'v5.lambda.phi'
      ENV['CAMERATA_VERSION'] = 'v6.lambda.phi'
      example.run
      ENV['MANAGEMENT_VERSION'] = original_management_version
      ENV['POSTGRES_VERSION'] = original_postgres_version
      ENV['BLACKLIGHT_VERSION'] = original_blacklight_version
      ENV['SOLR_VERSION'] = original_solr_version
      ENV['IIIF_IMAGE_VERSION'] = original_iiif_image_version
      ENV['IIIF_MANIFEST_VERSION'] = original_iiif_manifest_version
      ENV['CAMERATA_VERSION'] = original_camerata_version
    end
    before do
      visit root_path
    end

    it 'dynamically displays deployed services' do
      expect(page).to have_content("Containers")
      expect(page).to have_selector("#management_version", text: "v1.beta.gamma"),
                      "has a css id for the management version"
      expect(page).to have_content("yalelibraryit/dc-management")
      expect(page).to have_content("v7.delta.omicron")
      expect(page).to have_content("yalelibraryit/dc-postgres")
      expect(page).to have_content("v2.alpha.sigma")
      expect(page).to have_content("yalelibraryit/dc-blacklight")
      expect(page).to have_content("v3.alpha.omega")
      expect(page).to have_content("yalelibraryit/dc-solr")
      expect(page).to have_content("v4.delta.chi")
      expect(page).to have_content("yalelibraryit/dc-iiif-cantaloupe")
      expect(page).to have_content("v5.lambda.phi")
      expect(page).to have_content("yalelibraryit/dc-management")
      expect(page).to have_content("v6.lambda.phi")
      expect(page).to have_content("yalelibrary/yul-dc-camerata")
    end
  end
end
