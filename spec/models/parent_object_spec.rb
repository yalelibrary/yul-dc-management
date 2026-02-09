# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ParentObject, type: :model, prep_metadata_sources: true, prep_admin_sets: true do
  let(:ladybird) { 1 }
  let(:voyager) { 2 }
  let(:aspace) { 3 }
  let(:unexpected_metadata_source) { 4 }
  let(:logger_mock) { instance_double('Rails.logger').as_null_object }

  around do |example|
    original_metadata_sample_bucket = ENV['SAMPLE_BUCKET']
    ENV['SAMPLE_BUCKET'] = 'yul-dc-development-samples'
    original_path_ocr = ENV['OCR_DOWNLOAD_BUCKET']
    ENV['OCR_DOWNLOAD_BUCKET'] = 'yul-dc-ocr-test'
    original_access_primary_mount = ENV['ACCESS_PRIMARY_MOUNT']
    ENV['ACCESS_PRIMARY_MOUNT'] = File.join('spec', 'fixtures', 'images', 'access_primaries')
    example.run
    ENV['SAMPLE_BUCKET'] = original_metadata_sample_bucket
    ENV['OCR_DOWNLOAD_BUCKET'] = original_path_ocr
    ENV['ACCESS_PRIMARY_MOUNT'] = original_access_primary_mount
  end

  before do
    stub_metadata_cloud('2004628', 'ladybird')
    stub_metadata_cloud('2005512', 'ladybird')
    stub_metadata_cloud('AS-2005512', 'aspace')
    stub_metadata_cloud('V-2004628', 'ils')
    stub_metadata_cloud('2034600', 'ladybird')
    stub_metadata_cloud('16414889')
    stub_metadata_cloud('14716192')
    stub_metadata_cloud('16854285')
    stub_metadata_cloud('AS-16797069', 'aspace')
    stub_metadata_cloud('AS-16854285', 'aspace')
    stub_ptiffs_and_manifests
    stub_full_text('1030368')
    stub_full_text('1032318')
    stub_full_text('16057781')
    stub_full_text('16057782')
    stub_full_text('16057783')
    stub_full_text('16057784')
    stub_full_text('1042003')
    stub_request(:any, /localhost:8182*/).to_return(body: '{"service_id": 123123, "width": 10, "height": 10}')
  end

  context 'with four child objects', :has_vcr do
    let(:user) { FactoryBot.create(:user) }
    let(:parent_of_four) do
      FactoryBot.create(:parent_object, oid: 16_797_069, visibility: 'Public', authoritative_metadata_source_id: aspace, aspace_uri: '/repositories/11/archival_objects/608223', child_object_count: 4)
    end
    let(:child_of_four_one) { FactoryBot.create(:child_object, oid: 16_057_781, parent_object: parent_of_four) }
    let(:child_of_four_two) { FactoryBot.create(:child_object, oid: 16_057_782, parent_object: parent_of_four) }
    let(:child_of_four_three) { FactoryBot.create(:child_object, oid: 16_057_783, parent_object: parent_of_four) }
    let(:child_of_four_four) { FactoryBot.create(:child_object, oid: 16_057_784, parent_object: parent_of_four) }
    let(:batch_process) { FactoryBot.create(:batch_process, user: user) }
    around do |example|
      original_vpn = ENV['VPN']
      ENV['VPN'] = 'false'
      perform_enqueued_jobs do
        example.run
      end
      ENV['VPN'] = original_vpn
    end
    before do
      parent_of_four
      child_of_four_one
      child_of_four_two
      child_of_four_three
      child_of_four_four
      stub_request(:post, "#{ENV['SOLR_BASE_URL']}/blacklight-test/update?wt=json")
        .to_return(status: 200)
    end
    # rubocop:disable RSpec/AnyInstance
    it 'receives a check for whether it is ready for manifests 4 times, one for each child' do
      VCR.use_cassette('process csv') do
        allow(S3Service).to receive(:s3_exists?).and_return(false)
        parent_of_four.child_objects.each do |child_object|
          stub_full_text(child_object.oid)
        end
        allow_any_instance_of(ChildObject).to receive(:parent_object).and_return(parent_of_four)
        expect(parent_of_four).to receive(:needs_a_manifest?).exactly(4).times
        parent_of_four.setup_metadata_job
      end
    end

    # rubocop:enable RSpec/AnyInstance
    context 'with full_text? true' do
      around do |example|
        original_ocr_path = ENV['OCR_DOWNLOAD_BUCKET']
        ENV['OCR_DOWNLOAD_BUCKET'] = 'yul-dc-ocr-test'
        perform_enqueued_jobs do
          example.run
        end
        ENV['OCR_DOWNLOAD_BUCKET'] = original_ocr_path
      end

      before do
        allow(parent_of_four).to receive(:full_text?).and_return(true)
        allow(parent_of_four).to receive(:manifest_completed?).and_return(true).exactly(4).times
        parent_of_four.default_fetch
      end

      context 'with full text not found in s3' do
        before do
          allow(parent_of_four).to receive(:full_text?).and_call_original
          stub_full_text_not_found('16057782')
          parent_of_four.default_fetch
          recreate_children parent_of_four
          parent_of_four.update_fulltext
        end
        it 'becomes a partial fulltext' do
          solr_document = parent_of_four.to_solr_full_text.first
          expect(solr_document).not_to be_nil
          expect(solr_document[:has_fulltext_ssi].to_s).to eq 'Partial'
          expect(parent_of_four.extent_of_full_text).to eq 'Partial'
        end
        it 'does not include nil in child records' do
          child_solr_documents = parent_of_four.to_solr_full_text.second
          expect(child_solr_documents).not_to be_nil
          expect(child_solr_documents).not_to include(nil)
        end
      end

      context 'with full text in s3' do
        before do
          parent_of_four.child_objects.each do |child_object|
            stub_full_text(child_object.oid)
          end
          parent_of_four.update_fulltext
        end

        it 'indexes the full text' do
          solr_document = parent_of_four.to_solr_full_text.first
          expect(solr_document).not_to be_nil
          expect(solr_document[:fulltext_tesim].to_s).to include('много трудившейся')
          expect(solr_document[:has_fulltext_ssi].to_s).to eq 'Yes'
          expect(parent_of_four.extent_of_full_text).to eq 'Yes'
        end
      end

      context 'with the field set on the parent object' do
        it 'includes the field in the document generated by to_solr' do
          solr_document = parent_of_four.to_solr
          expect(solr_document[:has_fulltext_ssi].to_s).to eq 'None'
          parent_of_four.extent_of_full_text = 'Yes'
          solr_document = parent_of_four.to_solr
          expect(solr_document[:has_fulltext_ssi].to_s).to eq 'Yes'
        end
      end
    end
  end

  context 'with a parent object with many pages' do
    let(:admin_set) { AdminSet.find_by(key: 'brbl') }
    let(:parent_object) { FactoryBot.create(:parent_object, oid: 30_000_317, authoritative_metadata_source_id: aspace, aspace_uri: '/repositories/11/archival_objects/329771') }
    let(:child_object_one) { FactoryBot.create(:child_object, parent_object: parent_object, label: 'primero') }
    let(:child_object_two) { FactoryBot.create(:child_object, parent_object: parent_object, label: 'segundo') }
    let(:user) { FactoryBot.create(:user) }

    around do |example|
      perform_enqueued_jobs do
        example.run
      end
    end

    before do
      stub_metadata_cloud('AS-30000317', 'aspace')
      parent_object
      child_object_one
      child_object_two
      user.add_role(:editor, admin_set)
      login_as(:user)
    end

    it 'orders child_oids, child_labels, and child_objects based on order field' do
      oid1 = parent_object.child_oids.first
      oid2 = parent_object.child_oids.second
      label1 = parent_object.child_labels.first
      label2 = parent_object.child_labels.second
      child1 = parent_object.child_objects.first
      child2 = parent_object.child_objects.second
      parent_object.child_objects.first.update(order: 2)
      parent_object.child_objects.second.update(order: 1)
      parent_object.reload
      expect(parent_object.child_oids.first).to eq(oid2)
      expect(parent_object.child_oids.second).to eq(oid1)
      expect(parent_object.child_labels.first).to eq(label2)
      expect(parent_object.child_labels.second).to eq(label1)
      expect(parent_object.child_objects.first).to eq(child2)
      expect(parent_object.child_objects.second).to eq(child1)
    end
  end

  context 'with a random notification' do
    let(:user_one) { FactoryBot.create(:user, uid: 'human the first') }
    let(:user_two) { FactoryBot.create(:user, uid: 'human the second') }
    let(:user_three) { FactoryBot.create(:user, uid: 'human the third') }
    before do
      user_one
      user_two
      user_three
      stub_request(:head, "https://#{ENV['SAMPLE_BUCKET']}.s3.amazonaws.com/manifests/00/20/34/60/2034600.json")
        .to_return(status: 200)
      stub_request(:head, "https://#{ENV['SAMPLE_BUCKET']}.s3.amazonaws.com/manifests/12/20/05/51/2005512.json")
        .to_return(status: 200)
      stub_request(:head, "https://#{ENV['SAMPLE_BUCKET']}.s3.amazonaws.com/manifests/89/16/41/48/89/16414889.json")
        .to_return(status: 200)
      stub_request(:head, "https://#{ENV['SAMPLE_BUCKET']}.s3.amazonaws.com/manifests/92/14/71/61/92/14716192.json")
        .to_return(status: 200)
      stub_request(:head, "https://#{ENV['SAMPLE_BUCKET']}.s3.amazonaws.com/manifests/85/16/85/42/85/16854285.json")
        .to_return(status: 200)
    end
    around do |example|
      perform_enqueued_jobs do
        example.run
      end
    end
    let(:batch_process) { FactoryBot.create(:batch_process, user: user_one) }
    let(:csv_upload) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, 'csv', 'shorter_fixture_ids.csv')) }

    it 'returns a processing_event message' do
      expect do
        batch_process.file = csv_upload
        batch_process.save
        batch_process.run_callbacks :create
      end.to change { batch_process.batch_connections.where(connectable_type: 'ParentObject').count }.from(0).to(1)
        .and change { IngestEvent.count }.from(0).to(7)
      statuses = IngestEvent.all.map(&:status)
      expect(statuses).to include 'processing-queued'
      expect(statuses).to include 'metadata-fetch-skipped'
      expect(statuses).to include 'child-records-created'
      expect(statuses).to include 'processing-queued'
      expect(statuses).to include 'manifest-saved'
      expect(statuses).to include 'solr-indexed'
      expect(statuses).to include 'pdf-generated'
      expect(IngestEvent.all.map(&:reason)).to include 'Processing has been queued'
    end
    # rubocop:disable RSpec/AnyInstance
    it 'checks for solr success' do
      # TODO: Why not factorybot?
      po_actual = ParentObject.create(oid: 2_034_600, admin_set: FactoryBot.create(:admin_set))
      allow_any_instance_of(ParentObject).to receive(:solr_index).and_return('responseHeader' => { 'status' => 404, 'QTime' => 106 })
      batch_connection = batch_process.batch_connections.build(connectable: po_actual)
      gn = GenerateManifestJob.new
      gn.perform(po_actual, batch_process, batch_connection)
      statuses = IngestEvent.where(batch_connection: po_actual.batch_connections.first).map(&:status)
      expect(statuses).not_to include 'solr-indexed'
    end
    # rubocop:enable RSpec/AnyInstance
  end

  context 'determining whether it is newly created' do
    let(:parent_object) do
      FactoryBot.create(:parent_object,
      admin_set: FactoryBot.create(:admin_set),
      authoritative_metadata_source_id: aspace,
      aspace_uri: '/repositories/11/archival_objects/214638',
      child_object_count: 2,
      last_aspace_update: nil)
    end

    it 'can determine whether it is freshly from ASpace' do
      expect(parent_object.from_source_for_the_first_time?('aspace')).to eq true
      expect(parent_object.from_upstream_for_the_first_time?).to eq true
      parent_object.last_aspace_update = Time.zone.now
      parent_object.save!
      expect(parent_object.from_source_for_the_first_time?('aspace')).to eq false
      expect(parent_object.from_upstream_for_the_first_time?).to eq false
    end
  end

  context do
    let(:parent_object) { FactoryBot.create(:parent_object) }

    it 'will not overwrite the project id set after initial ingest' do
      json = JSON.parse(File.open('spec/fixtures/ladybird/2004628.json').read)
      parent_object.ladybird_json = json
      expect(parent_object.project_identifier).to eq '8'
      parent_object.project_identifier = 3
      parent_object.save!
      parent_object.ladybird_json = json
      expect(parent_object.project_identifier).to eq '3'
    end
  end

  context 'a newly created ParentObject with different visibilities' do
    let(:parent_object_nil) { described_class.create(visibility: nil) }
    it 'nil does not validate' do
      expect(parent_object_nil.valid?).to eq false
    end

    let(:parent_object) { described_class.create(oid: 123, admin_set: FactoryBot.create(:admin_set), visibility: 'Restricted Access') }
    it 'visibility defaults to Private if not a valid visibility' do
      expect(parent_object.valid?).to eq true
      expect(parent_object.visibility).to eq 'Private'
    end

    let(:parent_object_public) { described_class.create(oid: '2005512', visibility: 'Public', admin_set: FactoryBot.create(:admin_set)) }
    it 'Public visibility does validate' do
      expect(parent_object_public.valid?).to eq true
      expect(parent_object_public.visibility).to eq 'Public'
    end

    let(:parent_object_invalid_owp) { described_class.create(oid: '12345', visibility: 'Open with Permission', admin_set: FactoryBot.create(:admin_set)) }
    it 'open with Permission visibility does not validate without a permission set' do
      expect(parent_object_invalid_owp.valid?).to eq false
    end

    let(:permission_set) { FactoryBot.create(:permission_set, label: 'set 1') }
    let(:parent_object_owp) { described_class.create(oid: '54321', visibility: 'Open with Permission', admin_set: FactoryBot.create(:admin_set), permission_set_id: permission_set.id) }
    it 'open with Permission visibility validates with a permission set' do
      expect(parent_object_owp.valid?).to eq true
      expect(parent_object_owp.visibility).to eq 'Open with Permission'
    end
  end

  context "When trying to create a ParentObject" do
    it "requires an admin_set to be valid" do
      parent_object = ParentObject.new(oid: "2004628", authoritative_metadata_source_id: "1")
      expect(parent_object).not_to be_valid
    end
  end

  context 'a newly created ParentObject with an unexpected authoritative_metadata_source' do
    let(:unexpected_metadata_source) { FactoryBot.create(:metadata_source, id: 45, metadata_cloud_name: 'foo', display_name: 'Foo', file_prefix: 'F-') }
    let(:parent_object) { FactoryBot.create(:parent_object, oid: '2004628', authoritative_metadata_source: unexpected_metadata_source) }
    it 'raises an error when trying to get the authoritative_json for an unexpected metadata source' do
      expect { parent_object.authoritative_json }.to raise_error(StandardError)
    end
  end

  context 'without ladybird_json or identifiers set' do
    let(:parent_object) { FactoryBot.build(:parent_object, oid: '16797069') }

    it 'raises an error when building a voyager url' do
      expect { parent_object.voyager_cloud_url }.to raise_error(StandardError, 'Bib id required to build Voyager url')
    end

    it 'returns an aspace url' do
      expect { parent_object.aspace_cloud_url }.to raise_error(StandardError, 'ArchivesSpace uri required to build ArchivesSpace url')
    end
  end

  context 'a newly created ParentObject with an expected (alma or aspace) authoritative_metadata_source' do
    let(:parent_object) { FactoryBot.create(:parent_object, oid: '2005512', authoritative_metadata_source_id: aspace, aspace_uri: '/repositories/11/archival_objects/214638', child_object_count: 2) }
    let(:child_object_one) { FactoryBot.create(:child_object, oid: '1030368', parent_object: parent_object) }
    let(:child_object_two) { FactoryBot.create(:child_object, oid: '1032318', parent_object: parent_object) }

    around do |example|
      perform_enqueued_jobs do
        example.run
      end
    end

    before do
      stub_metadata_cloud('AS-2005512', 'aspace')
      parent_object
      child_object_one
      child_object_two
    end

    it 'creates and has a count of ChildObjects' do
      expect(parent_object.reload.child_object_count).to eq 2
      expect(ChildObject.where(parent_object_oid: '2005512').count).to eq 2
      expect(ChildObject.where(parent_object_oid: '2005512').first.order).to eq 1
    end

    it 'creates and has correct DependentObjects' do
      expect(parent_object.reload.dependent_objects.count).to eq 6
      expect(parent_object.dependent_objects.first.metadata_source).to eq 'aspace'
      expect(parent_object.dependent_objects.first.dependent_uri).to eq '/aspace/repositories/11/top_containers/19359'
    end

    it 'deletes DependentObjects when redirected' do
      expect(parent_object.reload.dependent_objects.count).to eq 6
      parent_object.redirect_to = 'https://collections.library.yale.edu/catalog/5555'
      parent_object.save
      expect(parent_object.dependent_objects.count).to eq 0
    end

    context 'a newly created ParentObject with just the minimal required attributes' do
      let(:parent_object) do
        described_class.create(oid: '2005512', admin_set: AdminSet.find_by(key: 'brbl'), authoritative_metadata_source_id: aspace, aspace_uri: '/repositories/11/archival_objects/214638',
                               child_object_count: 2, visibility: 'Public', bib: '3435140')
      end
      let(:child_object_one) { FactoryBot.create(:child_object, oid: '1030368', parent_object: parent_object) }
      let(:child_object_two) { FactoryBot.create(:child_object, oid: '1032318', parent_object: parent_object) }
      before do
        stub_metadata_cloud('AS-2005512', 'aspace')
        stub_metadata_cloud('2005512', 'ladybird')
        stub_metadata_cloud('V-2005512', 'ils')
        parent_object
        child_object_one
        child_object_two
      end

      it 'pulls from the MetadataCloud for ASpace and not Voyager or Ladybird' do
        expect(parent_object.reload.authoritative_metadata_source_id).to eq aspace
        expect(parent_object.aspace_json).not_to be nil
        expect(parent_object.aspace_json).not_to be_empty
        expect(parent_object.voyager_json).to be nil
        expect(parent_object.ladybird_json).to be nil
      end

      it 'pulls the rights statement from ASpace' do
        expect(parent_object.reload.rights_statement).to include 'The materials are open for research'
      end

      it 'assigns the call number and container grouping' do
        parent_object.reload
        expect(parent_object.call_number).to eq 'GEN MSS 257'
        expect(parent_object.container_grouping).to eq 'Box 3, folder 24'
      end

      it 'skips Voyager metadata fetch when the authoritative_metadata_source is changed to Voyager' do
        expect(parent_object.reload.authoritative_metadata_source_id).to eq aspace
        parent_object.authoritative_metadata_source_id = voyager
        parent_object.save!
        expect(parent_object.reload.authoritative_metadata_source_id).to eq voyager
        # Metadata fetch is skipped for ils (voyager)
        expect(parent_object.voyager_json).to be nil
      end

      it 'preserves Solr record and manifest when changing from ASpace to ILS', solr: true do
        # Ensure parent has aspace metadata, child objects, and has been indexed
        parent_object.reload
        expect(parent_object.aspace_json).not_to be_nil
        expect(parent_object.child_object_count).to eq 2

        # Index to Solr
        parent_object.solr_index
        solr = SolrService.connection
        response = solr.get 'select', params: { q: "oid_ssi:#{parent_object.oid}" }
        expect(response['response']['numFound']).to eq 1
        original_solr_doc = response['response']['docs'].first
        original_title = original_solr_doc['title_tesim']
        expect(original_title).to eq(['The gold pen used by Lincoln to sign the Emancipation Proclamation in the Executive Mansion, Washington, D.C., 1863 Jan 1'])

        # Generate manifest
        allow(parent_object).to receive(:manifest_completed?).and_return(true)
        parent_object.iiif_presentation.save
        manifest_content = S3Service.download(parent_object.iiif_presentation.manifest_path)
        expect(manifest_content).not_to be_nil

        # Change source to ils - fetch is skipped but existing data should remain
        parent_object.authoritative_metadata_source_id = voyager
        parent_object.save!

        # Verify source changed
        expect(parent_object.reload.authoritative_metadata_source_id).to eq voyager

        # Verify Solr record still exists with aspace data (unchanged)
        response = solr.get 'select', params: { q: "oid_ssi:#{parent_object.oid}" }
        expect(response['response']['numFound']).to eq 1
        updated_solr_doc = response['response']['docs'].first
        expect(updated_solr_doc['title_tesim']).to eq(original_title)

        # Verify manifest still exists
        manifest_content_after = S3Service.download(parent_object.iiif_presentation.manifest_path)
        expect(manifest_content_after).not_to be_nil
        expect(manifest_content_after).to eq(manifest_content)
      end

      it 'creates and has a count of ChildObjects' do
        expect(parent_object.reload.child_object_count).to eq 2
        expect(ChildObject.where(parent_object_oid: '2005512').count).to eq 2
      end

      it 'generated pdf json correctly' do
        expect(parent_object.pdf_generator_json).not_to be_nil
      end

      it 'generated pdf json with correct link to production DL' do
        expect(parent_object.pdf_generator_json).to include("https://collections.library.yale.edu/catalog/#{parent_object.oid}")
      end

      it 'generates pdf json with the correct preprocessing command' do
        expect(parent_object.pdf_generator_json).to include('"imageProcessingCommand":"vipsthumbnail %s --size 2000x2000 -o %s"')
      end

      it 'generates pdf json for checksum with the original preprocessing command' do
        expect(parent_object.pdf_json("same", :child_modification)).to include('"imageProcessingCommand":"vipsthumbnail %s --size 2000x2000 -o %s"')
      end

      it 'generated pdf json with Extent of Digitization' do
        parent_object.digitization_note = 'Test Digitization Note'
        expect(parent_object.pdf_generator_json).to include("{\"name\":\"Digitization Note\",\"value\":\"Test Digitization Note\"}")
      end

      it 'pdf path on S3' do
        expect(parent_object.remote_pdf_path).not_to be_nil
      end

      it 'generates pdf json with the image ids for each child' do
        pdf_json = parent_object.pdf_generator_json
        parent_object.child_objects.each do |child|
          expect(pdf_json).to include('{"name":"Image ID:","value":"' + child.oid.to_s + '"}')
        end
      end

      it 'pdf json checksum does not change when child has irrelevant changes' do
        checksum1 = parent_object.pdf_json_checksum
        parent_object.child_objects[0].viewing_hint = 'different'
        checksum2 = parent_object.pdf_json_checksum
        expect(checksum1).to eq(checksum2)
      end

      it 'pdf json checksum does change when child has relevant changes' do
        checksum1 = parent_object.pdf_json_checksum
        parent_object.child_objects[0].label = 'different'
        checksum2 = parent_object.pdf_json_checksum
        expect(checksum1).to eq(checksum2)
      end

      it 'returns true from needs_a_manifest? only one time' do
        parent_object.generate_manifest = true
        parent_object.save!
        expect(parent_object.needs_a_manifest?).to be_truthy
        expect(parent_object.needs_a_manifest?).to be_falsey
      end
    end

    context 'a parent object with children' do
      let(:parent_object) { described_class.create(oid: '2004628', admin_set: FactoryBot.create(:admin_set)) }
      before do
        stub_metadata_cloud('2004628')
        stub_request(:head, 'https://yul-dc-ocr-test.s3.amazonaws.com/fulltext/03/10/42/00/1042003.txt')
        .to_return(status: 200, headers: { 'Content-Type' => 'text/plain' })
        parent_object.update_fulltext
      end

      it 'can determine if any of their children have fulltext availability' do
        expect(parent_object.full_text?).to eq(true)
      end
    end

    context 'a newly created ParentObject with Voyager as authoritative_metadata_source' do
      let(:parent_object) { described_class.create(oid: '2004628', bib: '3163155', authoritative_metadata_source_id: voyager, admin_set: FactoryBot.create(:admin_set)) }

      it 'skips metadata fetch for Voyager (ils) source' do
        expect(parent_object.reload.authoritative_metadata_source_id).to eq voyager
        expect(parent_object.ladybird_json).to be nil
        expect(parent_object.voyager_json).to be nil
        expect(parent_object.aspace_json).to be nil
      end

      it 'can return the json from its authoritative_metadata_source' do
        expect(parent_object.authoritative_json).to eq parent_object.voyager_json
      end
    end

    # rubocop:disable Layout/LineLength
    context 'a newly created ParentObject with Ladybird and multiple rights statements' do
      let(:parent_object) { described_class.create(oid: '2005512', admin_set: AdminSet.find_by(key: 'brbl'), authoritative_metadata_source_id: aspace, aspace_uri: '/repositories/11/archival_objects/214638') }
      before do
        stub_metadata_cloud('AS-2005512', 'aspace')
      end

      it 'indexes all rights statements and concats with new lines' do
        expect(parent_object.reload.rights_statement).to include "The Abraham Lincoln Collection is the physical property of the Beinecke Rare Book and Manuscript Library, Yale University. Literary rights, including copyright, belong to the authors or their legal heirs and assigns. For further information, consult the appropriate curator.\nThe materials are open for research."
      end
    end
    # rubocop:enable Layout/LineLength

    context 'a newly created ParentObject with ArchiveSpace as authoritative_metadata_source' do
      let(:parent_object) do
        described_class.create(
          oid: '2012036',
          aspace_uri: '/repositories/11/archival_objects/555049',
          bib: '6805375',
          barcode: '39002091459793',
          authoritative_metadata_source_id: aspace,
          admin_set: FactoryBot.create(:admin_set)
        )
      end
      before do
        stub_metadata_cloud('2012036', 'ladybird')
        stub_metadata_cloud('AS-2012036', 'aspace')
      end

      it 'pulls from the MetadataCloud for ArchiveSpace' do
        expect(parent_object.reload.authoritative_metadata_source_id).to eq aspace # 3 is ArchiveSpace
        expect(parent_object.ladybird_json).to be nil
        expect(parent_object.aspace_json).not_to be nil
        expect(parent_object.aspace_json).not_to be_empty
        expect(parent_object.voyager_json).to be nil
      end

      it 'correctly sets the bib and barcode on the parent object' do
        expect(parent_object.bib).to eq '6805375'
        expect(parent_object.barcode).to eq '39002091459793'
      end

      it 'stores dependent objects property' do
        expect(parent_object.reload.dependent_objects.count).to eq 37
        expect(parent_object.dependent_objects.all? { |dobj| dobj.metadata_source == 'aspace' }).to be_truthy
      end
    end

    context "has a shortcut for the metadata_cloud_name" do
      it 'returns source name when authoritative source is set' do
        expect(parent_object.source_name).to eq 'aspace'
      end

      it 'returns nil when authoritative source is not set' do
        expect(ParentObject.new(authoritative_metadata_source_id: nil).source_name).to eq nil
      end
    end

    context 'with aspace_json' do
      it 'returns a ladybird url' do
        expect(parent_object.ladybird_cloud_url).to eq "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/1.0.1/ladybird/oid/2005512?include-children=1"
      end

      it 'returns a voyager url' do
        parent_object.bib = '3435140'
        parent_object.barcode = '39002075038423'
        parent_object.save!
        expect(parent_object.voyager_cloud_url).to eq "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/1.0.1/ils/barcode/39002075038423?bib=3435140"
      end

      it 'returns an aspace url' do
        expect(parent_object.aspace_cloud_url).to eq "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/1.0.1/aspace/repositories/11/archival_objects/214638"
      end

      context 'with the wrong metadata_cloud_version set' do
        let(:ladybird_source) { MetadataSource.first }
        around do |example|
          original_vpn = ENV['VPN']
          ENV['VPN'] = 'true'
          example.run
          ENV['VPN'] = original_vpn
        end
        it 'raises an error with wrong version' do
          stub_request(:get, "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/clearly_fake_version/ladybird/oid/2005512?include-children=1")
              .to_return(status: 400, body: File.open(File.join(fixture_path, 'metadata_cloud_wrong_version.json')))
          allow(MetadataSource).to receive(:metadata_cloud_version).and_return('clearly_fake_version')
          expect(parent_object.ladybird_cloud_url).to eq "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/clearly_fake_version/ladybird/oid/2005512?include-children=1"
          expect do
            ladybird_source.fetch_record_on_vpn(parent_object)
          end.to raise_error(MetadataSource::MetadataCloudVersionError, 'MetadataCloud is not responding to requests for version: clearly_fake_version')
        end
        it 'raises an error with 500 response' do
          stub_request(:get, "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/1.0.1/ladybird/oid/2005512?include-children=1")
              .to_return(status: 500, body: { error: 'fake error' }.to_json)
          expect(parent_object.ladybird_cloud_url).to eq "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/1.0.1/ladybird/oid/2005512?include-children=1"
          expect do
            ladybird_source.fetch_record_on_vpn(parent_object)
          end.to raise_error(MetadataSource::MetadataCloudServerError, 'MetadataCloud is responding with 5XX error')
        end
        it 'returns false on out of range response' do
          stub_request(:get, "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/1.0.1/ladybird/oid/2005512?include-children=1")
              .to_return(status: 700, body: { error: 'fake error' }.to_json)
          expect(parent_object.ladybird_cloud_url).to eq "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/1.0.1/ladybird/oid/2005512?include-children=1"
          expect(ladybird_source.fetch_record_on_vpn(parent_object)).to be_falsey
        end
        it 'returns response' do
          stub_request(:get, "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/1.0.1/ladybird/oid/2005512?include-children=1")
              .to_return(status: 200, body: { data: 'fake data' }.to_json)
          expect(parent_object.ladybird_cloud_url).to eq "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/1.0.1/ladybird/oid/2005512?include-children=1"
          allow(S3Service).to receive(:upload_if_changed).and_return true
          record = ladybird_source.fetch_record(parent_object)
          expect(record['data']).to eq('fake data')
        end
      end
    end

    context 'with vpn true' do
      around do |example|
        original_vpn = ENV['VPN']
        ENV['VPN'] = 'true'
        original_flags = ENV['FEATURE_FLAGS']
        ENV['FEATURE_FLAGS'] = "#{ENV['FEATURE_FLAGS']}|DO-SEND|" unless original_flags&.include?('|DO-SEND|')
        example.run
        ENV['VPN'] = original_vpn
        ENV['FEATURE_FLAGS'] = original_flags
      end

      before do
        stub_full_text_not_found('2005512')
        stub_request(:get, "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/1.0.1/ladybird/oid/2005512?include-children=1")
            .to_return(status: 200, body: { 'title' => ['data'] }.to_json)
        stub_request(:get, "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/1.0.1/aspace/repositories/11/archival_objects/515305")
            .to_return(status: 200, body: { 'title' => ['data'] }.to_json)
        allow(S3Service).to receive(:upload_if_changed).and_return(true)
      end

      it 'has digital object json when private' do
        expect(parent_object.ladybird_cloud_url).to eq "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/1.0.1/ladybird/oid/2005512?include-children=1"
        parent_object.aspace_uri = '/repositories/11/archival_objects/515305'
        parent_object.authoritative_metadata_source_id = aspace
        parent_object.child_object_count = 1
        parent_object.visibility = 'Private'
        parent_object.aspace_json = { 'title': ['test'] }
        expect(parent_object.digital_object_json_available?).to be_truthy
        expect(JSON.parse(parent_object.generate_digital_object_json)['visibility']).to eq('Private')
      end

      it 'does not have digital object json when redirected' do
        expect(parent_object.ladybird_cloud_url).to eq "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/1.0.1/ladybird/oid/2005512?include-children=1"
        parent_object.aspace_uri = '/repositories/11/archival_objects/515305'
        parent_object.authoritative_metadata_source_id = aspace
        parent_object.child_object_count = 1
        parent_object.visibility = 'Public'
        parent_object.redirect_to = 'https://collections.library.yale.edu/catalog/32432'
        parent_object.aspace_json = { 'title': ['test'] }
        expect(parent_object.digital_object_json_available?).to be_falsey
      end

      it 'posts digital object changes when source changes' do
        stub_request(:post, "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/digital_object_updates")
            .to_return(status: 200, body: { data: 'fake data' }.to_json)
        expect(parent_object.ladybird_cloud_url).to eq "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/1.0.1/ladybird/oid/2005512?include-children=1"
        parent_object.aspace_uri = '/repositories/11/archival_objects/515305'
        parent_object.authoritative_metadata_source_id = aspace
        parent_object.child_object_count = 1
        parent_object.visibility = 'Public'
        expect(parent_object).to receive(:mc_post).once.and_return(OpenStruct.new(status: 200))
        parent_object.aspace_json = { 'title': ['test title'] }
        parent_object.solr_index
      end

      it 'posts digital object update when visibility changes from Public to Yale Community Only' do
        expect(parent_object.ladybird_cloud_url).to eq "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/1.0.1/ladybird/oid/2005512?include-children=1"
        parent_object.aspace_uri = '/repositories/11/archival_objects/515305'
        parent_object.authoritative_metadata_source_id = aspace
        parent_object.child_object_count = 1
        parent_object.visibility = 'Public'
        parent_object.aspace_json = { 'title': ['test title'] }
        expect(parent_object).to receive(:mc_post).twice.and_return(OpenStruct.new(status: 200)) # once for first save, again for visibility change
        parent_object.solr_index
        parent_object.visibility = 'Yale Community Only'
        parent_object.solr_index
      end

      it 'posts digital object update when visibility changes from Yale Community Only to Public' do
        expect(parent_object.ladybird_cloud_url).to eq "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/1.0.1/ladybird/oid/2005512?include-children=1"
        parent_object.aspace_uri = '/repositories/11/archival_objects/515305'
        parent_object.authoritative_metadata_source_id = aspace
        parent_object.child_object_count = 1
        parent_object.visibility = 'Yale Community Only'
        parent_object.aspace_json = { 'title': ['test title'] }
        expect(parent_object).to receive(:mc_post).twice.and_return(OpenStruct.new(status: 200)) # once for first save, again for visibility change
        parent_object.solr_index
        parent_object.visibility = 'Public'
        parent_object.solr_index
      end

      it 'posts digital object changes when parent is deleted' do
        stub_request(:post, "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/digital_object_updates")
            .to_return(status: 200, body: { data: 'fake data' }.to_json)
        expect(parent_object.ladybird_cloud_url).to eq "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/1.0.1/ladybird/oid/2005512?include-children=1"
        parent_object.aspace_uri = '/repositories/11/archival_objects/515305'
        parent_object.authoritative_metadata_source_id = aspace
        parent_object.child_object_count = 1
        parent_object.visibility = 'Public'
        expect(parent_object).to receive(:mc_post).twice.and_return(OpenStruct.new(status: 200))
        parent_object.aspace_json = { 'title': ['test title'] }
        parent_object.save!
        parent_object.solr_index
        parent_object.reload
        parent_object.solr_index
      end

      it 'deletes DigitalObjectJson on delete' do
        stub_request(:post, "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/digital_object_updates")
            .to_return(status: 200, body: { data: 'fake data' }.to_json)
        expect(parent_object.ladybird_cloud_url).to eq "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/1.0.1/ladybird/oid/2005512?include-children=1"
        parent_object.aspace_uri = '/repositories/11/archival_objects/515305'
        parent_object.authoritative_metadata_source_id = aspace
        parent_object.child_object_count = 1
        parent_object.visibility = 'Public'
        expect(parent_object).to receive(:mc_post).and_return(OpenStruct.new(status: 200)).at_least(:once)
        parent_object.aspace_json = { 'title': ['test title'] }
        parent_object.save!
        parent_object.solr_index
        parent_object.reload
        parent_object.authoritative_metadata_source_id = ladybird
        parent_object.save!
        parent_object.solr_index
        parent_object.reload
        parent_object.digital_object_delete
        parent_object.reload
        expect(parent_object.digital_object_json).to be_nil
      end

      it 'posts digital object changes when source changes, and continues if post fails' do
        stub_request(:post, "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/digital_object_updates")
            .to_return(status: 200, body: { data: 'fake data' }.to_json)
        stub_full_text_not_found('2005512')
        allow(parent_object).to receive(:mc_post).and_raise('boom!')
        parent_object.aspace_uri = '/repositories/11/archival_objects/515305'
        parent_object.authoritative_metadata_source_id = aspace
        parent_object.child_object_count = 1
        parent_object.visibility = 'Public'
        parent_object.save!
      end

      it 'posts digital object changes when source changes, and continues if MC doesn not return 200' do
        stub_full_text_not_found('2005512')
        stub_request(:post, "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/digital_object_updates")
            .to_return(status: 404, body: { data: 'fake data' }.to_json)
        parent_object.aspace_uri = '/repositories/11/archival_objects/515305'
        parent_object.authoritative_metadata_source_id = aspace
        parent_object.child_object_count = 1
        parent_object.visibility = 'Public'
        parent_object.save!
      end
    end

    context 'with vpn true' do
      around do |example|
        original_vpn = ENV['VPN']
        ENV['VPN'] = 'true'
        original_flags = ENV['FEATURE_FLAGS']
        ENV['FEATURE_FLAGS'] = "#{ENV['FEATURE_FLAGS']}|ACTIVITY-SEND|" unless original_flags&.include?('|ACTIVITY-SEND|')
        example.run
        ENV['VPN'] = original_vpn
        ENV['FEATURE_FLAGS'] = original_flags
      end

      before do
        stub_full_text_not_found('2005512')
        stub_request(:get, "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/1.0.1/aspace/repositories/11/archival_objects/214638")
            .to_return(status: 200, body: { 'title' => ['data'] }.to_json)
        stub_request(:get, "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/1.0.1/aspace/repositories/11/archival_objects/515305")
            .to_return(status: 200, body: { 'title' => ['data'] }.to_json)
        allow(S3Service).to receive(:upload_if_changed).and_return(true)
      end

      it 'get dcs activity changes when parent changes' do
        stub_full_text_not_found('2005512')
        stub_request(:get, "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/streams/activity/dcs/oid/2005512/Create")
            .to_return(status: 200)
        parent_object.extent_of_digitization = 'Completely digitized'
        parent_object.save!
        expect(DcsActivityStreamUpdate.exists?(oid: 2_005_512)).to eq true
      end

      it 'get dcs activity changes when get failed' do
        stub_full_text_not_found('2005512')
        stub_request(:get, "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/streams/activity/dcs/oid/2005512/Create")
            .to_return(status: 404)
        parent_object.extent_of_digitization = 'Completely digitized'
        parent_object.save!
        expect(DcsActivityStreamUpdate.exists?(oid: 2_005_512)).to eq true
      end
    end

    context 'with a bib but no barcode' do
      let(:parent_object) { FactoryBot.build(:parent_object, oid: '16712419', bib: '1289001') }

      it 'returns a voyager url using the bib' do
        expect(parent_object.voyager_cloud_url).to eq "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/1.0.1/ils/bib/1289001"
      end
    end

    context 'with no children, therefore no child captions, labels or oids' do
      before do
        stub_metadata_cloud("AS-781086", "aspace")
      end
      let(:parent_object_with_no_children) { FactoryBot.create(:parent_object, oid: '781086', authoritative_metadata_source_id: aspace, aspace_uri: '/repositories/12/archival_objects/781086') }

      it 'returns an empty array' do
        parent_object_with_no_children.reload
        expect(parent_object_with_no_children.child_captions).to be_empty
        expect(parent_object_with_no_children.child_captions).to be_an(Array)
        expect(parent_object_with_no_children.child_labels).to be_empty
        expect(parent_object_with_no_children.child_labels).to be_an(Array)
        expect(parent_object_with_no_children.child_oids).to be_empty
        expect(parent_object_with_no_children.child_oids).to be_an(Array)
      end

      it 'is marked as ready for manifest' do
        expect(parent_object_with_no_children.reload.ready_for_manifest?).to eq true
      end
    end

    context 'with children but no child captions or labels' do
      let(:parent_object_with_children) do
        FactoryBot.create(:parent_object, oid: '10001192', authoritative_metadata_source_id: aspace, aspace_uri: '/repositories/12/archival_objects/10001192', child_object_count: 4)
      end
      let(:child_object_uno) { FactoryBot.create(:child_object, oid: '1052971', parent_object: parent_object_with_children, caption: nil) }
      let(:child_object_dos) { FactoryBot.create(:child_object, oid: '1052972', parent_object: parent_object_with_children, caption: nil) }
      let(:child_object_tres) { FactoryBot.create(:child_object, oid: '1052973', parent_object: parent_object_with_children, caption: nil) }
      let(:child_object_cuatro) { FactoryBot.create(:child_object, oid: '1052974', parent_object: parent_object_with_children, caption: nil) }
      before do
        stub_metadata_cloud('AS-10001192', 'aspace')
        parent_object_with_children
        child_object_uno
        child_object_dos
        child_object_tres
        child_object_cuatro
      end

      it 'counts the parent objects children' do
        expect(parent_object_with_children.reload.child_objects.count).to eq 4
      end

      it 'returns an empty array if the child object has no captions or labels' do
        parent_object_with_children.reload
        expect(parent_object_with_children.child_captions).to be_an(Array)
        expect(parent_object_with_children.child_captions).to be_empty
        expect(parent_object_with_children.child_labels).to be_an(Array)
        expect(parent_object_with_children.child_labels).to be_empty
        expect(parent_object_with_children.child_oids).to be_an(Array)
        expect(parent_object_with_children.child_oids).to contain_exactly(1_052_971, 1_052_972, 1_052_973, 1_052_974)
        expect(parent_object_with_children.child_oids.size).to eq 4
      end
    end

    context 'with children that have captions and labels' do
      before do
        parent_object.child_objects.first.update(caption: 'This is a caption')
        parent_object.child_objects.first.update(label: 'This is a label')
        parent_object.child_objects.first.save!
      end

      it 'returns an array of the child object\'s caption and label' do
        expect(parent_object.reload.child_captions).to eq ['1030368: This is a caption', '1032318: MyString']
        expect(parent_object.reload.child_labels).to eq ['This is a label']
        expect(parent_object.reload.child_oids).to contain_exactly(1_030_368, 1_032_318)
      end

      it 'returns an array of the child object\'s captions and labels' do
        parent_object.child_objects.second.update(caption: 'This is another caption')
        parent_object.child_objects.second.update(label: 'This is another label')
        expect(parent_object.reload.child_captions.size).to eq 2
        expect(parent_object.reload.child_captions).to contain_exactly('1030368: This is a caption', '1032318: This is another caption')
        expect(parent_object.reload.child_labels.size).to eq 2
        expect(parent_object.reload.child_labels).to contain_exactly('This is a label', 'This is another label')
        expect(parent_object.reload.child_oids).to contain_exactly(1_030_368, 1_032_318)
      end

      it 'is marked as not ready for manifest unless explicitly told to create one' do
        expect(parent_object.reload.generate_manifest).to eq false
        expect(parent_object.reload.needs_a_manifest?).to eq false
      end
    end
  end

  context 'with correct visibility value' do
    let(:parent_object) { described_class.create(oid: '2004628', visibility: 'Public') }
    it 'returns visibility' do
      expect(parent_object.visibility).to eq 'Public'
    end

    it 'returns nil when authoritative source is not set' do
      expect(ParentObject.new(authoritative_metadata_source_id: nil).source_name).to eq nil
    end
  end

  context 'chooses correct values for container information' do
    let(:parent_object) { described_class.create(oid: '2004628', visibility: 'Public') }
    it 'returns container grouping if present' do
      expect(parent_object.extract_container_information('containerGrouping' => 'container info', 'box' => 'box 1', 'folder' => 'folder 1', 'volumeEnumeration' => 'VE 101')).to eq 'container info'
    end
    it 'returns box, folder if containerGrouping not present' do
      expect(parent_object.extract_container_information('box' => 'box 1', 'folder' => 'folder 1', 'volumeEnumeration' => 'VE 101')).to eq 'box 1, folder 1'
    end
    it 'returns volumeEnumeration if other fields not present' do
      expect(parent_object.extract_container_information('volumeEnumeration' => 'VE 101')).to eq 'VE 101'
    end
  end

  context 'a new ParentObject with no info' do
    it 'has the expected defaults' do
      po = described_class.new
      expect(po.oid).to be nil
      expect(po.project_identifier).to be nil
      expect(po.bib).to be nil
      expect(po.holding).to be nil
      expect(po.item).to be nil
      expect(po.barcode).to be nil
      expect(po.aspace_uri).to be nil
      expect(po.last_ladybird_update).to be nil
      expect(po.last_id_update).to be nil
      expect(po.last_voyager_update).to be nil
      expect(po.last_aspace_update).to be nil
      expect(po.visibility).to eq "Private"
      expect(po.ladybird_json).to be nil
      expect(po.voyager_json).to be nil
      expect(po.aspace_json).to be nil
      expect(po.viewing_direction).to be nil
      expect(po.display_layout).to be nil
      expect(po.child_object_count).to be nil
      expect(po.authoritative_metadata_source_id).to eq ladybird
      expect(po.rights_statement).to be nil
    end
  end

  context 'a Parent Object' do
    it 'finds batch connections to the batch process' do
      user = FactoryBot.create(:user)
      parent_object = FactoryBot.create(:parent_object, oid: 2_003_431)
      batch_process = BatchProcess.new(oid: parent_object.oid, user: user)
      batch_process.batch_connections.build(connectable: parent_object)
      batch_process.save!
      batch_connection = parent_object.batch_connections

      expect(parent_object.batch_connections_for(batch_process)).to eq(batch_connection)
    end
  end

  context 'a ladybird Object without itemPermission' do
    let(:parent_object) { described_class.create(oid: '16688180', admin_set: FactoryBot.create(:admin_set)) }
    before do
      stub_metadata_cloud('16688180')
    end

    it 'will have Private as the default visibility' do
      expect(parent_object.visibility).to eq 'Private'
    end
  end

  context 'a newly created ParentObject with an expected (voyager) authoritative_metadata_source' do
    around do |example|
      perform_enqueued_jobs do
        example.run
      end
    end
    context 'with voyager_json' do
      let(:parent_object) do
        FactoryBot.build(:parent_object, oid: '16797069', bib: '3435140', item: '8114701',
                                         authoritative_metadata_source_id: voyager,
                                         voyager_json: JSON.parse(File.read(File.join(fixture_path, 'ils', 'V-16797069.json'))))
      end

      it 'returns a voyager url' do
        source = MetadataSource.find(parent_object.authoritative_metadata_source_id)
        expect(source.url_type).to eq 'voyager_cloud_url'
        parent_object.holding = nil
        expect(parent_object.voyager_cloud_url).to eq "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/1.0.1/ils/item/8114701?bib=3435140"
      end
    end
  end

  context 'a newly created ParentObject with an expected (aspace) authoritative_metadata_source' do
    around do |example|
      perform_enqueued_jobs do
        example.run
      end
    end
    context 'with aspace_json' do
      let(:parent_object) do
        FactoryBot.build(:parent_object, oid: '2012036', bib: '3435140', barcode: '39002075038423',
                                         authoritative_metadata_source_id: aspace,
                                         aspace_uri: '/repositories/11/archival_objects/555049',
                                         aspace_json: JSON.parse(File.read(File.join(fixture_path, 'aspace', 'AS-2012036.json'))))
      end

      it 'returns an aspace url' do
        source = MetadataSource.find(parent_object.authoritative_metadata_source_id)
        expect(source.url_type).to eq 'aspace_cloud_url'
        expect(parent_object.aspace_cloud_url).to eq "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/1.0.1/aspace/repositories/11/archival_objects/555049"
      end
    end
  end

  context 'a parent_object handles json' do
    let(:parent_object) do
      FactoryBot.build(:parent_object, oid: nil, bib: '500', item: nil,
                                       authoritative_metadata_source_id: voyager)
    end
    let(:json_integers) { { 'bibId' => 500, 'holdingId' => 10, 'itemId' => 30 } }
    let(:json_integers_0_item) { { 'bibId' => 500, 'holdingId' => 10, 'itemId' => 0 } }
    let(:json_strings) { { 'bibId' => '500', 'holdingId' => '10', 'itemId' => '30' } }
    let(:alma_json_strings) { { 'mmsId' => '123456789', 'holdingId' => '987654321', 'pid' => '12345' } }
    let(:json_strings_0_item) { { 'bibId' => '500', 'holdingId' => '10', 'itemId' => '0' } }
    it 'accepts integer ids for sierra' do
      parent_object.sierra_json = json_integers
      expect(parent_object.item).to eq('30')
    end
    it 'accepts string ids for sierra' do
      parent_object.sierra_json = json_strings
      expect(parent_object.item).to eq('30')
    end
    it 'accepts string ids for alma' do
      parent_object.alma_json = alma_json_strings
      expect(parent_object.alma_item).to eq('12345')
      expect(parent_object.alma_holding).to eq('987654321')
      expect(parent_object.mms_id).to eq('123456789')
    end
    it 'accepts string ids with 0 item for sierra' do
      parent_object.sierra_json = json_strings_0_item
      expect(parent_object.item).to be_nil
    end
    it 'accepts integer ids with 0 item for sierra' do
      parent_object.sierra_json = json_integers_0_item
      expect(parent_object.item).to be_nil
    end
    it 'accepts integer ids for ils' do
      parent_object.voyager_json = json_integers
      expect(parent_object.holding).to eq('10')
      expect(parent_object.item).to eq('30')
    end
    it 'accepts string ids with 0 item for ils' do
      parent_object.voyager_json = json_strings_0_item
      expect(parent_object.holding).to eq('10')
      expect(parent_object.item).to be_nil
    end
    it 'accepts integer ids with 0 item for ils' do
      parent_object.voyager_json = json_integers_0_item
      expect(parent_object.holding).to eq('10')
      expect(parent_object.item).to be_nil
    end
  end

  describe ParentObject do
    it { is_expected.to have_many(:permission_requests) }
  end
end
