# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BatchProcess, type: :system, prep_metadata_sources: true, prep_admin_sets: true, solr: true do
  subject(:batch_process) { BatchProcess.new }
  let(:admin_set) { FactoryBot.create(:admin_set, key: 'brbl') }
  let(:user) { FactoryBot.create(:user, uid: "mk2525") }
  let(:preservica_parent_with_children) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "preservica", "preservica_parent_with_children.csv")) }
  let(:preservica_sync) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "preservica", "preservica_sync.csv")) }
  let(:first_tif) { "spec/fixtures/images/access_masters/00/01/20/00/00/00/200000001.tif" }
  let(:second_tif) { "spec/fixtures/images/access_masters/00/02/20/00/00/00/200000002.tif" }
  let(:third_tif) { "spec/fixtures/images/access_masters/00/03/20/00/00/00/200000003.tif" }

  around do |example|
    preservica_host = ENV['PRESERVICA_HOST']
    preservica_creds = ENV['PRESERVICA_CREDENTIALS']
    ENV['PRESERVICA_HOST'] = "testpreservica"
    ENV['PRESERVICA_CREDENTIALS'] = '{"brbl": {"username":"xxxxx", "password":"xxxxx"}}'
    access_host = ENV['ACCESS_MASTER_MOUNT']
    ENV['ACCESS_MASTER_MOUNT'] = File.join("spec", "fixtures", "images", "access_masters")
    perform_enqueued_jobs do
      example.run
    end
    ENV['PRESERVICA_HOST'] = preservica_host
    ENV['PRESERVICA_CREDENTIALS'] = preservica_creds
    ENV['ACCESS_MASTER_MOUNT'] = access_host
  end

  before do
    login_as user
    batch_process.user_id = user.id
    stub_preservica_aspace_single
    stub_preservica_login
    stub_preservica_fixtures_set_of_three_changing_generation
    stub_preservica_tifs_set_of_three
  end

  context 'user with edit permission' do
    before do
      user.add_role(:editor, admin_set)
      login_as user
    end

    it 'can recognize when there is a new generation and bitstream in preservica' do
      File.delete(first_tif) if File.exist?(first_tif)
      File.delete(second_tif) if File.exist?(second_tif)
      File.delete(third_tif) if File.exist?(third_tif)

      allow(S3Service).to receive(:s3_exists?).and_return(false)
      expect(File.exist?(first_tif)).to be false
      expect(File.exist?(second_tif)).to be false
      expect(File.exist?(third_tif)).to be false
      expect do
        batch_process.file = preservica_parent_with_children
        batch_process.save
      end.to change { ChildObject.count }.from(0).to(3)

      visit batch_process_path(batch_process.id)
      expect(page).to have_content 'Batch complete'

      expect(File.exist?(first_tif)).to be true
      expect(File.exist?(second_tif)).to be true
      expect(File.exist?(third_tif)).to be true

      po_first = ParentObject.first
      visit "/batch_processes/#{batch_process.id}/parent_objects/#{po_first.oid}"
      # solr doesn't complete - all other stages have timestamp - this confirms pending appears no more than once
      expect(page).not_to have_content('Pending').twice

      co_first = po_first.child_objects.first
      expect(po_first.last_preservica_update).not_to be nil
      expect(co_first.preservica_generation_uri).to eq "https://preservica-dev-v6.library.yale.edu/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b486/generations/1"
      expect(co_first.preservica_bitstream_uri).to eq "/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b486/generations/1/bitstreams/1"
      expect(co_first.ptiff_conversion_at.present?).to be_truthy
      expect(po_first.child_objects.count).to eq 3
      co_first.caption = 'test1'
      co_first.save

      sync_batch_process = BatchProcess.new(batch_action: 'resync with preservica', user: user)
      expect do
        sync_batch_process.file = preservica_sync
        sync_batch_process.save!
      end.not_to change { ChildObject.count }
      # downloads new tif to pairtree
      expect(po_first.iiif_manifest['items'].count).to eq 3
      expect(po_first.iiif_manifest['items'][0]['id']).to eq "http://localhost/manifests/oid/200000000/canvas/200000001"
      expect(po_first.iiif_manifest['items'][1]['id']).to eq "http://localhost/manifests/oid/200000000/canvas/200000002"
      expect(po_first.iiif_manifest['items'][2]['id']).to eq "http://localhost/manifests/oid/200000000/canvas/200000003"

      po_first = ParentObject.first
      visit "/batch_processes/#{sync_batch_process.id}/parent_objects/#{po_first.oid}"
      expect(page).not_to have_content('Pending').twice
      expect(page).not_to have_content("#{po_first.oid}").twice
      co_first = po_first.child_objects.first
      expect(co_first.preservica_generation_uri).to eq "https://preservica-dev-v6.library.yale.edu/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b486/generations/1_new"
      expect(co_first.preservica_bitstream_uri).to eq "/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b486/generations/1/bitstreams/1"
      expect(co_first.caption).to eq "test1"
      File.delete(first_tif) if File.exist?(first_tif)
      File.delete(second_tif) if File.exist?(second_tif)
      File.delete(third_tif) if File.exist?(third_tif)
    end
  end
end
