# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'Structure Editor', type: :system, prep_metadata_sources: true, prep_admin_sets: true, js: true do
  let(:user) { FactoryBot.create(:sysadmin_user) }
  let(:admin_set) { FactoryBot.create(:admin_set, key: 'brbl', label: 'brbl') }
  # parent object has three child objects
  let(:parent_object) do
    FactoryBot.create(:parent_object, oid: 2_005_512, admin_set_id: admin_set.id, authoritative_metadata_source_id: 3, aspace_uri: '/repositories/11/archival_objects/214638', child_object_count: 2)
  end
  let(:child_object_one) { FactoryBot.create(:child_object, oid: 1_329_643, parent_object: parent_object) }
  let(:child_object_two) { FactoryBot.create(:child_object, oid: 1_329_644, parent_object: parent_object) }
  let(:iiif_presentation) { IiifPresentationV3.new(parent_object) }

  around do |example|
    original_manifests_base_url = ENV['IIIF_MANIFESTS_BASE_URL']
    original_image_base_url = ENV['IIIF_IMAGE_BASE_URL']
    original_pdf_url = ENV['PDF_BASE_URL']
    original_path_ocr = ENV['OCR_DOWNLOAD_BUCKET']
    ENV['IIIF_MANIFESTS_BASE_URL'] = 'http://localhost/manifests'
    ENV['IIIF_IMAGE_BASE_URL'] = 'http://localhost:8182/iiif'
    ENV['PDF_BASE_URL'] = 'http://localhost/pdfs'
    ENV['OCR_DOWNLOAD_BUCKET'] = 'yul-dc-ocr-test'
    perform_enqueued_jobs do
      example.run
    end
    ENV['IIIF_MANIFESTS_BASE_URL'] = original_manifests_base_url
    ENV['IIIF_IMAGE_BASE_URL'] = original_image_base_url
    ENV['PDF_BASE_URL'] = original_pdf_url
    ENV['OCR_DOWNLOAD_BUCKET'] = original_path_ocr
  end

  before do
    stub_metadata_cloud('AS-2005512', 'aspace')
    stub_ptiffs
    stub_pdfs
    user.add_role(:editor, admin_set)
    login_as user
    parent_object
    child_object_one
    child_object_two
    stub_request(:get, "https://#{ENV['SAMPLE_BUCKET']}.s3.amazonaws.com/manifests/12/20/05/51/12/2005512.json")
      .to_return(status: 200, body: File.open(File.join(fixture_path, 'manifests', '2107188.json')).read)
    stub_request(:put, "https://#{ENV['SAMPLE_BUCKET']}.s3.amazonaws.com/manifests/12/20/05/51/12/2005512.json")
      .to_return(status: 200)
    # The parent object gets its metadata populated via a background job, and we can't assume that has run,
    # so stub the part of the metadata we need for the iiif_presentation
    allow(parent_object).to receive(:authoritative_json).and_return(JSON.parse(File.read(File.join(fixture_path, 'aspace', 'AS-2005512.json'))))
  end

  describe 'can access the homepage' do
    it 'can render a manifest' do
      visit edit_parent_object_path(2_005_512)
      expect(page).to have_content('Manifest Structure')
      click_on 'Manifest Structure'
      page.driver.browser.switch_to.window(page.driver.browser.window_handles.last)
      expect(page).to have_content('2005512')
    end
  end

  describe 'can perform actions and' do
    before do
      visit edit_parent_object_path(2_005_512)
      expect(page).to have_content('Manifest Structure')
      click_on 'Manifest Structure'
      page.driver.browser.switch_to.window(page.driver.browser.window_handles.last)
      click_on 'OK'
    end

    it 'can add a range' do
      click_on 'Range +'
      expect(page).to have_content('New Range')
    end

    it 'can add a canvas' do
      click_on 'Range +'
      find('.ant-tree-title').click
      find('.item-label', match: :first).click
      click_on 'Canvas +'
      expect(page).to have_content('1329643').twice
    end

    it 'can delete a range' do
      click_on 'Range +'
      find('.ant-tree-title').click
      find('.fa-xmark').click
      expect(page).not_to have_content('New Range')
    end

    it 'can delete a canvas' do
      click_on 'Range +'
      find('.ant-tree-title').click
      find('.item-label', match: :first).click
      click_on 'Canvas +'
      # finds the canvas label
      find(:xpath, '(//span[@class="ant-tree-title"])[2]').click
      find('.fa-xmark').click
      expect(page).to have_content('1329643').once
    end

    it 'can change range title' do
      click_on 'Range +'
      # finds range label
      find(:xpath, '(//html/body/div/section/section/aside/div/div/div[3]/div/div/div/div[1]/span[4]/span/span/span[2]/span)').double_click
      find(:xpath, '//html/body/div/section/section/aside/div/div/div[3]/div/div/div/div[1]/span[4]/span/span/span[2]').fill_in with: 'Different Range'
      find('.item-label', match: :first).click
      expect(page).to have_content('Different Range')
    end

    it 'can submit structure back to management' do
      click_on 'Range +'
      click_on 'Submit'
      expect(page).to have_content('Manifest Saved')
      visit '/parent_objects/2005512/manifest.json'
      expect(page).to have_content('New Range')
    end
  end
end
