# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'Batch Process Child detail page', type: :system, prep_metadata_sources: true, prep_admin_sets: true, js: true do
  context 'with expected success with a csv import' do
    let(:user) { FactoryBot.create(:user, uid: 'johnsmith2531') }
    let(:brbl) { AdminSet.find_by_key('brbl')  }
    let(:sml) { AdminSet.find_by_key('sml') }
    let(:batch_process) do
      FactoryBot.create(
        :batch_process,
        batch_action: 'export child oids',
        user_id: user.id,
        csv: File.open(fixture_path + '/csv/shorter_fixture_ids.csv').read,
        file_name: 'shorter_fixture_ids.csv',
        created_at: '2020-10-08 14:17:01'
      )
    end
    let(:parent_object) do
      FactoryBot.create(:parent_object, admin_set_id: brbl.id, authoritative_metadata_source_id: 3, aspace_uri: '/repositories/11/archival_objects/214638', child_object_count: 2)
    end
    let(:child_object_one) { FactoryBot.create(:child_object, oid: '1030368', parent_object: parent_object) }
    let(:child_object_two) { FactoryBot.create(:child_object, oid: '1032318', parent_object: parent_object) }

    around do |example|
      access_primary_mount = ENV['ACCESS_PRIMARY_MOUNT']
      ENV['ACCESS_PRIMARY_MOUNT'] = '/data'
      original_path_ocr = ENV['OCR_DOWNLOAD_BUCKET']
      ENV['OCR_DOWNLOAD_BUCKET'] = 'yul-dc-ocr-test'
      perform_enqueued_jobs do
        example.run
      end
      ENV['ACCESS_PRIMARY_MOUNT'] = access_primary_mount
      ENV['OCR_DOWNLOAD_BUCKET'] = original_path_ocr
    end

    before do
      stub_metadata_cloud('AS-2005512', 'aspace')
      stub_ptiffs_and_manifests
      user.add_role(:editor, brbl)
      login_as user
      aspace_response = JSON.parse(File.read(File.join(fixture_path, 'aspace', 'AS-2005512.json')))
      parent_object
      parent_object.aspace_json = aspace_response
      parent_object.save!
      child_object_one
      child_object_two
    end

    it 'has a link to the batch process detail page' do
      batch_process.save!
      parent_oid = parent_object.oid
      child_oid = child_object_one.oid

      expect(BatchProcess.all.count).to eq 1
      visit show_child_batch_process_path(child_oid: child_oid, id: batch_process.id, oid: parent_oid)
      # has a link to the batch process detail page
      expect(page).to have_link(batch_process&.id&.to_s, href: "/batch_processes/#{batch_process.id}")
      # has a link to the parent object page
      expect(page).to have_link(parent_oid.to_s, href: "/batch_processes/#{batch_process.id}/parent_objects/#{parent_oid}")
      # has a link to the child object page
      expect(page).to have_link("#{child_oid} (current record)", href: "/child_objects/#{child_oid}")
      # shows the status of the child object
      expect(page).to have_content('Pending')
      # shows the duration of the batch process
      expect(page).to have_content('seconds')
    end
  end

  context 'with expected failure with an integrity check job' do
    let(:user) { FactoryBot.create(:user, uid: 'johnsmith25312') }
    let(:parent_object) { FactoryBot.create(:parent_object, oid: '444', child_object_count: 1, authoritative_metadata_source: MetadataSource.first, admin_set: AdminSet.first) }
    let(:child_object) { FactoryBot.create(:child_object, oid: '567890', parent_object: parent_object, file_size: 1234, checksum: 'f3755c5d9e086b4522a0d3916e9a0bfcbd47564ef') }

    around do |example|
      access_primary_mount = ENV['ACCESS_PRIMARY_MOUNT']
      ENV['ACCESS_PRIMARY_MOUNT'] = File.join(fixture_path, 'images/ptiff_images')
      perform_enqueued_jobs do
        example.run
      end
      ENV['ACCESS_PRIMARY_MOUNT'] = access_primary_mount
    end

    before do
      login_as user
      allow(GoodJob).to receive(:preserve_job_records).and_return(true)
      ActiveJob::Base.queue_adapter = GoodJob::Adapter.new(execution_mode: :inline)
      stub_request(:get, File.join(child_object.access_primary_path)).to_return(status: 200, body: File.open(File.join(child_object.access_primary_path)).read)
    end
    # rubocop:disable Layout/LineLength
    it 'will allow user to update the child object checksum' do
      expect(child_object.sha512_checksum).to be_nil
      expect(child_object.reload.sha256_checksum).to be_nil
      expect(child_object.reload.md5_checksum).to be_nil
      expect(child_object.checksum).to eq('f3755c5d9e086b4522a0d3916e9a0bfcbd47564ef')
      expect(child_object.file_size).to eq(1234)
      expect { ChildObjectIntegrityCheckJob.new.perform }.to change { IngestEvent.count }.by(3)
      expect(child_object.events_for_batch_process(BatchProcess.where(batch_action: 'integrity check'))[0].reason).to eq "The Child Object: #{child_object.oid} - has a checksum mismatch. The checksum of the image file saved to this child oid does not match the checksum of the image file in the database. This may mean that the image has been corrupted. Please verify integrity of image for Child Object: #{child_object.oid} - by manually comparing the checksum values and update record as necessary."
      visit show_child_batch_process_path(child_oid: child_object.oid, id: BatchProcess.where(batch_action: 'integrity check')[0].id, oid: parent_object.oid)
      expect(page).to have_link('Update Checksum')
      click_on 'Update Checksum'
      expect(child_object.reload.sha512_checksum).to eq('d6e3926fbe14fedbf3a568b6a5dbdb3e8b2312f217daa460a743559d41a688af4a7c701e7bac908fc7e3fd51c505fa01dad9eee96fcfd2666e92c648249edf02')
      expect(child_object.reload.checksum).to be_nil
      expect(child_object.reload.sha256_checksum).to be_nil
      expect(child_object.reload.md5_checksum).to be_nil
      expect(child_object.file_size).to eq(1_131_966)
      expect(page).to have_content('Child object has been queued for update.')
    end
    # rubocop:enable Layout/LineLength
  end
end
