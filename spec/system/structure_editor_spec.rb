# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "Structure Editor", type: :system, prep_metadata_sources: true, prep_admin_sets: true, js: true do
  let(:user) { FactoryBot.create(:sysadmin_user) }
  let(:admin_set) { FactoryBot.create(:admin_set, key: 'brbl', label: 'brbl') }
  # parent object has three child objects
  let(:parent_object) { FactoryBot.create(:parent_object, oid: '16172421', admin_set_id: admin_set.id) }
  let(:iiif_presentation) { IiifPresentationV3.new(parent_object) }

  around do |example|
    original_manifests_base_url = ENV['IIIF_MANIFESTS_BASE_URL']
    original_image_base_url = ENV["IIIF_IMAGE_BASE_URL"]
    original_pdf_url = ENV["PDF_BASE_URL"]
    original_path_ocr = ENV['OCR_DOWNLOAD_BUCKET']
    ENV['IIIF_MANIFESTS_BASE_URL'] = "http://localhost/manifests"
    ENV['IIIF_IMAGE_BASE_URL'] = "http://localhost:8182/iiif"
    ENV["PDF_BASE_URL"] = "http://localhost/pdfs"
    ENV['OCR_DOWNLOAD_BUCKET'] = "yul-dc-ocr-test"
    perform_enqueued_jobs do
      example.run
    end
    ENV['IIIF_MANIFESTS_BASE_URL'] = original_manifests_base_url
    ENV['IIIF_IMAGE_BASE_URL'] = original_image_base_url
    ENV["PDF_BASE_URL"] = original_pdf_url
    ENV['OCR_DOWNLOAD_BUCKET'] = original_path_ocr
  end

  before do
    stub_metadata_cloud("16172421")
    stub_ptiffs
    stub_pdfs
    user.add_role(:editor, admin_set)
    login_as user
    parent_object
    stub_request(:get, "https://#{ENV['SAMPLE_BUCKET']}.s3.amazonaws.com/manifests/21/16/17/24/21/16172421.json")
      .to_return(status: 200, body: File.open(File.join(fixture_path, "manifests", "16172421.json")).read)
    stub_request(:put, "https://#{ENV['SAMPLE_BUCKET']}.s3.amazonaws.com/manifests/21/16/17/24/21/16172421.json")
      .to_return(status: 200)
    # The parent object gets its metadata populated via a background job, and we can't assume that has run,
    # so stub the part of the metadata we need for the iiif_presentation
    allow(parent_object).to receive(:authoritative_json).and_return(JSON.parse(File.read(File.join(fixture_path, "ladybird", "16172421.json"))))
  end

  describe 'can access the homepage' do
    it 'can render a manifest' do
      visit '/structure-editor/'
      click_on 'Get Manifest'
      fill_in 'API Key', with: user.token
      fill_in 'Manifest', with: "#{root_path}parent_objects/16172421/manifest.json"
      click_on 'OK'
      # loads manifest
      expect(page).to have_content('Manifest Downloaded')
      # loads child objects
      expect(page).to have_content('16188699')
    end
  end

  describe 'can perform actions and' do
    before do
      visit '/structure-editor/'
      click_on 'Get Manifest'
      fill_in 'API Key', with: user.token
      fill_in 'Manifest', with: "#{root_path}parent_objects/16172421/manifest.json"
      # submit dialogue
      click_on 'OK'
      # acknowledge manifest loaded
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
      expect(page).to have_content('16188699').twice
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
      expect(page).to have_content('16188699').once
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
      visit '/parent_objects/16172421/manifest.json'
      expect(page).to have_content('New Range')
    end
  end
end
