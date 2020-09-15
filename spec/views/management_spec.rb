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
      expect(page).to have_selector("#postgres_version", text: "v7.delta.omicron"),
                      "has a css id for the postgres version"
      expect(page).to have_content("yalelibraryit/dc-postgres")
      expect(page).to have_selector("#blacklight_version", text: "v2.alpha.sigma"),
                      "has a css id for the blacklight version"
      expect(page).to have_content("yalelibraryit/dc-blacklight")
      expect(page).to have_selector("#solr_version", text: "v3.alpha.omega"),
                      "has a css id for the solr version"
      expect(page).to have_content("yalelibraryit/dc-solr")
      expect(page).to have_selector("#iiif_image_version", text: "v4.delta.chi"),
                      "has a css id for the iiif image version"
      expect(page).to have_content("yalelibraryit/dc-iiif-cantaloupe")
      expect(page).to have_selector("#iiif_manifest_version", text: "v5.lambda.phi")
      expect(page).to have_content("yalelibraryit/dc-iiif-manifest")
      expect(page).to have_selector("#camerata_version", text: "v6.lambda.phi"),
                      "has a css id for the camerata version"
      expect(page).to have_content("yalelibrary/yul-dc-camerata")
    end
  end
end
