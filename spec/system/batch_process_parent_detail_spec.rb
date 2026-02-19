# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'Batch Process Parent detail page', type: :system, prep_metadata_sources: true, prep_admin_sets: true, js: true do
  let(:user) { FactoryBot.create(:user, uid: 'handsomedan2530') }
  let(:batch_process) do
    FactoryBot.create(
      :batch_process,
      user: user,
      batch_action: 'export child oids',
      csv: File.open(fixture_path + '/csv/shorter_fixture_ids.csv').read,
      file_name: 'shorter_fixture_ids.csv',
      created_at: '2025-10-08 14:17:01'
    )
  end

  around do |example|
    original_image_bucket = ENV['S3_SOURCE_BUCKET_NAME']
    ENV['S3_SOURCE_BUCKET_NAME'] = 'yale-test-image-samples'
    original_path_ocr = ENV['OCR_DOWNLOAD_BUCKET']
    ENV['OCR_DOWNLOAD_BUCKET'] = 'yul-dc-ocr-test'
    perform_enqueued_jobs do
      example.run
    end
    ENV['S3_SOURCE_BUCKET_NAME'] = original_image_bucket
    ENV['OCR_DOWNLOAD_BUCKET'] = original_path_ocr
  end

  describe 'with a failure' do
    before do
      batch_process
      # ugh, why is it so hard to fake a failure?
    end

    xit 'sees the failures on the parent object for that batch process' do
      s3_double = class_double('S3Service')
      allow(s3_double).to receive(:download).and_return(nil)
      visit show_parent_batch_process_path(batch_process, 16_057_779)
      expect(page.body).to include('failed')
    end
  end

  describe 'with expected success' do
    let(:parent_object) do
      FactoryBot.create(:parent_object, oid: 2_005_512, admin_set: AdminSet.find_by_key('brbl'), child_object_count: 1, authoritative_metadata_source_id: 3,
                                        aspace_uri: '/repositories/11/archival_objects/214638')
    end
    let(:child_object) { FactoryBot.create(:child_object, oid: 100_368, parent_object: parent_object) }
    before do
      stub_metadata_cloud('AS-2005512', 'aspace')
      allow(S3Service).to receive(:s3_exists?).and_return(true)
      stub_ptiffs_and_manifests
      parent_object
      child_object
      batch_process.save!
      login_as user
      brbl = AdminSet.find_by_key('brbl')
      user.add_role(:editor, brbl)
      visit show_parent_batch_process_path(batch_process, 2_005_512)
    end

    describe 'with a csv import' do
      xit 'has a child object id' do # TODO: ensure child objects appear on parent detail page - due to pending status of child object creation the child oid is not displayed immediately
        expect(page).to have_content('100368')
      end

      it 'has a link to the batch process detail page' do
        expect(page).to have_link(batch_process&.id&.to_s, href: "/batch_processes/#{batch_process.id}")
      end

      it 'has a link to the parent object page' do
        expect(page).to have_link('2005512 (current record)', href: '/parent_objects/2005512')
      end

      it 'shows the status of the parent object' do
        expect(page).to have_content('Pending')
      end

      it 'shows when the parent object was submitted' do
        expect(page).to have_content('2025-10-08 14:17:01 UTC')
      end

      it 'has labels for the ingest steps for the parent object' do
        expect(page).to have_content('Metadata Fetched Pending')
        expect(page).to have_content('Manifest Saved Pending')
        expect(page).to have_content('Solr Indexed Pending')
        expect(page).to have_content('PDF Generated Pending')
        expect(page).to have_content('Child Records Created Pending')
      end
    end
  end
end
