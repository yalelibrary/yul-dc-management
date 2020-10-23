# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "Management", type: :feature do
  let(:user) { FactoryBot.create(:user) }
  describe 'index page' do
    around do |example|
      original_management_version = ENV['MANAGEMENT_VERSION']
      original_blacklight_version = ENV['BLACKLIGHT_VERSION']
      original_iiif_image_version = ENV['IIIF_IMAGE_VERSION']
      original_iiif_manifest_version = ENV['IIIF_MANIFEST_VERSION']
      ENV['MANAGEMENT_VERSION'] = 'v1.beta.gamma'
      ENV['BLACKLIGHT_VERSION'] = 'v2.alpha.sigma'
      ENV['IIIF_IMAGE_VERSION'] = 'v4.delta.chi'
      ENV['IIIF_MANIFEST_VERSION'] = 'v5.lambda.phi'
      example.run
      ENV['MANAGEMENT_VERSION'] = original_management_version
      ENV['BLACKLIGHT_VERSION'] = original_blacklight_version
      ENV['IIIF_IMAGE_VERSION'] = original_iiif_image_version
      ENV['IIIF_MANIFEST_VERSION'] = original_iiif_manifest_version
    end
    before do
      login_as user
      visit root_path
    end

    it 'dynamically displays deployed services' do
      expect(page).to have_content("Containers")
      expect(page).to have_selector("#management_version", text: "v1.beta.gamma"),
                      "has a css id for the management version"
      expect(page).to have_content("yalelibraryit/dc-management")
      expect(page).to have_selector("#blacklight_version", text: "v2.alpha.sigma"),
                      "has a css id for the blacklight version"
      expect(page).to have_content("yalelibraryit/dc-blacklight")
      expect(page).to have_selector("#iiif_image_version", text: "v4.delta.chi"),
                      "has a css id for the iiif image version"
      expect(page).to have_content("yalelibraryit/dc-iiif-cantaloupe")
      expect(page).to have_selector("#iiif_manifest_version", text: "v5.lambda.phi")
      expect(page).to have_content("yalelibraryit/dc-iiif-manifest")
    end
  end
end
