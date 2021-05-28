# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ParentObject, type: :model, prep_metadata_sources: true, prep_admin_sets: true do
  let(:ladybird) { 1 }
  let(:voyager) { 2 }
  let(:aspace) { 3 }
  let(:unexpected_metadata_source) { 4 }
  let(:logger_mock) { instance_double("Rails.logger").as_null_object }

  around do |example|
    original_metadata_sample_bucket = ENV['SAMPLE_BUCKET']
    ENV['SAMPLE_BUCKET'] = "yul-dc-development-samples"
    original_path_ocr = ENV['OCR_DOWNLOAD_BUCKET']
    ENV['OCR_DOWNLOAD_BUCKET'] = "yul-dc-ocr-test"
    example.run
    ENV['SAMPLE_BUCKET'] = original_metadata_sample_bucket
    ENV['OCR_DOWNLOAD_BUCKET'] = original_path_ocr
  end

  before do
    stub_metadata_cloud("2004628", "ladybird")
    stub_metadata_cloud("2005512", "ladybird")
    stub_metadata_cloud("V-2004628", "ils")
    stub_metadata_cloud("2034600", "ladybird")
    stub_metadata_cloud("16414889")
    stub_metadata_cloud("14716192")
    stub_metadata_cloud("16854285")
    stub_metadata_cloud("16057779")
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

  context "with four child objects", :has_vcr do
    let(:user) { FactoryBot.create(:user) }
    let(:parent_of_four) { FactoryBot.create(:parent_object, oid: 16_057_779) }
    let(:child_of_four) { FactoryBot.create(:child_object, oid: 456_789, parent_object: parent_of_four) }
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
      stub_request(:post, "#{ENV['SOLR_BASE_URL']}/blacklight-test/update?wt=json")
        .to_return(status: 200)
    end
    # rubocop:disable RSpec/AnyInstance
    it "receives a check for whether it's ready for manifests 4 times, one for each child" do
      parent_of_four.child_objects.each do |child_object|
        stub_full_text(child_object.oid)
      end
      allow_any_instance_of(ChildObject).to receive(:parent_object).and_return(parent_of_four)
      VCR.use_cassette("process csv") do
        expect(parent_of_four).to receive(:needs_a_manifest?).exactly(4).times
        parent_of_four.setup_metadata_job
      end
    end
    # rubocop:enable RSpec/AnyInstance
    context "with full_text? true" do
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

      context "with full text not found in s3" do
        before do
          stub_full_text_not_found("16057782")
        end
        it "raises exception" do
          allow(Rails.logger).to receive(:error) { :logger_mock }
          expect { parent_of_four.to_solr_full_text }.to raise_error("Missing full text for child object: 16057782, for parent object: 16057779")
        end
      end

      context "with full text in s3" do
        before do
          parent_of_four.child_objects.each do |child_object|
            stub_full_text(child_object.oid)
          end
        end

        it "indexes the full text" do
          solr_document = parent_of_four.to_solr_full_text.first
          expect(solr_document).not_to be_nil
          expect(solr_document[:fulltext_tesim].to_s).to include("много трудившейся")
        end
      end
    end
  end

  context "with a parent object with many pages" do
    let(:fixture_json) { JSON.parse(File.open(File.join(fixture_path, "ladybird", "2003431.json")).read) }
    let(:parent_object) { FactoryBot.create(:parent_object, oid: 2_003_431, ladybird_json: fixture_json) }

    around do |example|
      perform_enqueued_jobs do
        example.run
      end
    end

    it "creates the child objects" do
      expect do
        parent_object.create_child_records
      end.to change { ChildObject.count }.from(0).to(1366)
    end

    it "orders child_oids based on order field" do
      parent_object.create_child_records
      oid1 = parent_object.child_oids.first
      oid2 = parent_object.child_oids.second
      parent_object.child_objects.first.update(order: 2)
      parent_object.child_objects.second.update(order: 1)
      parent_object.reload
      expect(parent_object.child_oids.first).to eq(oid2)
      expect(parent_object.child_oids.second).to eq(oid1)
    end

    it "orders child_labels based on order field" do
      parent_object.create_child_records
      label1 = parent_object.child_labels.first
      label2 = parent_object.child_labels.second
      parent_object.child_objects.first.update(order: 2)
      parent_object.child_objects.second.update(order: 1)
      parent_object.reload
      expect(parent_object.child_labels.first).to eq(label2)
      expect(parent_object.child_labels.second).to eq(label1)
    end

    it "orders child_objects based on order field" do
      parent_object.create_child_records
      child1 = parent_object.child_objects.first
      child2 = parent_object.child_objects.second
      parent_object.child_objects.first.update(order: 2)
      parent_object.child_objects.second.update(order: 1)
      parent_object.reload
      expect(parent_object.child_objects.first).to eq(child2)
      expect(parent_object.child_objects.second).to eq(child1)
    end
  end

  context 'with a random notification' do
    let(:user_one) { FactoryBot.create(:user, uid: "human the first") }
    let(:user_two) { FactoryBot.create(:user, uid: "human the second") }
    let(:user_three) { FactoryBot.create(:user, uid: "human the third") }
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
    let(:parent_object) { FactoryBot.build(:parent_object, oid: 2_034_600) }
    let(:batch_process) { FactoryBot.create(:batch_process, user: user_one) }
    let(:csv_upload) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "short_fixture_ids.csv")) }

    it 'returns a processing_event message' do
      expect do
        batch_process.file = csv_upload
        batch_process.save
        batch_process.run_callbacks :create
      end.to change { batch_process.batch_connections.where(connectable_type: "ParentObject").count }.from(0).to(5)
        .and change { IngestEvent.count }.from(0).to(456)
      statuses = IngestEvent.all.map(&:status)
      expect(statuses).to include "processing-queued"
      expect(statuses).to include "metadata-fetched"
      expect(statuses).to include "child-records-created"
      expect(statuses).to include "ptiff-ready"
      expect(statuses).to include "manifest-saved"
      expect(statuses).to include "solr-indexed"
      expect(statuses).to include "pdf-generated"
      expect(IngestEvent.all.map(&:reason)).to include "Processing has been queued"
    end
    # rubocop:disable RSpec/AnyInstance
    it "checks for solr success" do
      po_actual = ParentObject.create(oid: 2_034_600, admin_set: FactoryBot.create(:admin_set))
      allow_any_instance_of(ParentObject).to receive(:solr_index).and_return("responseHeader" => { "status" => 404, "QTime" => 106 })
      batch_connection = batch_process.batch_connections.build(connectable: po_actual)
      gn = GenerateManifestJob.new
      gn.perform(po_actual, batch_process, batch_connection)
      statuses = IngestEvent.where(batch_connection: po_actual.batch_connections.first).map(&:status)
      expect(statuses).not_to include "solr-indexed"
    end
    # rubocop:enable RSpec/AnyInstance
  end

  context "determining whether it's newly created" do
    let(:parent_object) { FactoryBot.create(:parent_object) }

    it "can determine whether it's freshly from Ladybird" do
      parent_object.ladybird_json = JSON.parse(File.open("spec/fixtures/ladybird/2004628.json").read)
      expect(parent_object.from_ladybird_for_the_first_time?).to eq true
      expect(parent_object.from_upstream_for_the_first_time?).to eq true
      parent_object.save!
      expect(parent_object.from_ladybird_for_the_first_time?).to eq false
      expect(parent_object.from_upstream_for_the_first_time?).to eq false
    end
  end

  context "a newly created ParentObject with different visibilities" do
    let(:parent_object_nil) { described_class.create(visibility: nil) }
    it "nil does not validate" do
      expect(parent_object_nil.valid?).to eq false
    end

    let(:parent_object_restricted) { described_class.create(visibility: "Restricted Access") }
    it "other visibility does not validate" do
      expect(parent_object_restricted.valid?).to eq false
      expect(parent_object_restricted.visibility).to eq "Restricted Access"
    end

    let(:parent_object_public) { described_class.create(oid: "2005512", visibility: "Public", admin_set: FactoryBot.create(:admin_set)) }
    it "Public visibility does validate" do
      expect(parent_object_public.valid?).to eq true
      expect(parent_object_public.visibility).to eq "Public"
    end
  end

  context "When trying to create a ParentObject" do
    it "requires an admin_set to be valid" do
      parent_object = ParentObject.new(oid: "2004628", authoritative_metadata_source_id: "1")
      expect(parent_object).not_to be_valid
    end
  end

  context "a newly created ParentObject with an unexpected authoritative_metadata_source" do
    let(:unexpected_metadata_source) { FactoryBot.create(:metadata_source, id: 4, metadata_cloud_name: "foo", display_name: "Foo", file_prefix: "F-") }
    let(:parent_object) { FactoryBot.create(:parent_object, oid: "2004628", authoritative_metadata_source: unexpected_metadata_source) }
    it "raises an error when trying to get the authoritative_json for an unexpected metadata source" do
      expect { parent_object.authoritative_json }.to raise_error(StandardError)
    end
  end

  context 'without ladybird_json or identifiers set' do
    let(:parent_object) { FactoryBot.build(:parent_object, oid: '16797069') }

    it 'raises an error when building a voyager url' do
      expect { parent_object.voyager_cloud_url }.to raise_error(StandardError, "Bib id required to build Voyager url")
    end

    it 'returns an aspace url' do
      expect { parent_object.aspace_cloud_url }.to raise_error(StandardError, "ArchiveSpace uri required to build ArchiveSpace url")
    end
  end

  context "a newly created ParentObject with an expected (ladybird, voyager, or aspace) authoritative_metadata_source" do
    let(:parent_object) { FactoryBot.create(:parent_object, oid: "2005512", authoritative_metadata_source_id: ladybird) }

    around do |example|
      perform_enqueued_jobs do
        example.run
      end
    end

    it "creates and has a count of ChildObjects" do
      expect(parent_object.reload.child_object_count).to eq 2
      expect(ChildObject.where(parent_object_oid: "2005512").count).to eq 2
      expect(ChildObject.where(parent_object_oid: "2005512").first.order).to eq 1
    end

    context "a newly created ParentObject with just the oid and default authoritative_metadata_source (Ladybird for now)" do
      let(:parent_object) { described_class.create(oid: "2005512", admin_set: FactoryBot.create(:admin_set)) }
      before do
        stub_metadata_cloud("2005512", "ladybird")
        stub_metadata_cloud("V-2005512", "ils")
      end

      it "pulls from the MetadataCloud for Ladybird and not Voyager or ArchiveSpace" do
        expect(parent_object.reload.authoritative_metadata_source_id).to eq ladybird
        expect(parent_object.ladybird_json).not_to be nil
        expect(parent_object.ladybird_json).not_to be_empty
        expect(parent_object.visibility).to eq "Public"
        expect(parent_object.voyager_json).to be nil
        expect(parent_object.aspace_json).to be nil
      end

      it "pulls the rights statement from Ladybird" do
        expect(parent_object.reload.rights_statement).to include "The use of this image may be subject to the "
      end

      it "pulls Voyager record from the MetadataCloud when the authoritative_metadata_source is changed to Voyager" do
        expect(parent_object.reload.authoritative_metadata_source_id).to eq ladybird
        parent_object.authoritative_metadata_source_id = voyager
        parent_object.save!
        expect(parent_object.reload.authoritative_metadata_source_id).to eq voyager
        expect(parent_object.voyager_json).not_to be nil
      end

      it "creates and has a count of ChildObjects" do
        expect(parent_object.reload.child_object_count).to eq 2
        expect(ChildObject.where(parent_object_oid: "2005512").count).to eq 2
      end

      it "generated pdf json correctly" do
        expect(parent_object.pdf_generator_json).not_to be_nil
      end

      it "generated pdf json with correct link to production DL" do
        expect(parent_object.pdf_generator_json).to include("https://collections.library.yale.edu/catalog/#{parent_object.oid}")
      end

      it "generates pdf json with the correct preprocessing command" do
        expect(parent_object.pdf_generator_json).to include('"imageProcessingCommand":"convert -resize 2000x2000 %s[0] %s"')
      end

      it "pdf path on S3" do
        expect(parent_object.remote_pdf_path).not_to be_nil
      end

      it "returns true from needs_a_manifest? only one time" do
        parent_object.generate_manifest = true
        parent_object.save!
        expect(parent_object.needs_a_manifest?).to be_truthy
        expect(parent_object.needs_a_manifest?).to be_falsey
      end
    end

    context "a parent object with children" do
      let(:parent_object) { described_class.create(oid: "2004628", admin_set: FactoryBot.create(:admin_set)) }
      before do
        stub_metadata_cloud("2004628")
        stub_request(:head, "https://yul-dc-ocr-test.s3.amazonaws.com/fulltext/03/10/42/00/1042003.txt")
        .to_return(status: 200, headers: { 'Content-Type' => 'text/plain' })
      end

      it "can determine if any of it's children have fulltext availability" do
        expect(parent_object.full_text?).to eq(true)
      end
    end

    context "a newly created ParentObject with Voyager as authoritative_metadata_source" do
      let(:parent_object) { described_class.create(oid: "2004628", bib: '3163155', authoritative_metadata_source_id: voyager, admin_set: FactoryBot.create(:admin_set)) }

      it "pulls from the MetadataCloud for Voyager" do
        expect(parent_object.reload.authoritative_metadata_source_id).to eq voyager
        expect(parent_object.ladybird_json).to be nil
        expect(parent_object.voyager_json).not_to be nil
        expect(parent_object.voyager_json).not_to be_empty
        expect(parent_object.aspace_json).to be nil
      end

      it "can return the json from its authoritative_metadata_source" do
        expect(parent_object.authoritative_json).to eq parent_object.voyager_json
      end
    end

    context "a newly created ParentObject with ArchiveSpace as authoritative_metadata_source" do
      let(:parent_object) do
        described_class.create(
          oid: "2012036",
          aspace_uri: "/repositories/11/archival_objects/555049",
          authoritative_metadata_source_id: aspace,
          admin_set: FactoryBot.create(:admin_set)
        )
      end
      before do
        stub_metadata_cloud("2012036", "ladybird")
        stub_metadata_cloud("AS-2012036", "aspace")
      end

      it "pulls from the MetadataCloud for ArchiveSpace" do
        expect(parent_object.reload.authoritative_metadata_source_id).to eq aspace # 3 is ArchiveSpace
        expect(parent_object.ladybird_json).to be nil
        expect(parent_object.aspace_json).not_to be nil
        expect(parent_object.aspace_json).not_to be_empty
        expect(parent_object.voyager_json).to be nil
      end
    end

    context "has a shortcut for the metadata_cloud_name" do
      let(:parent_object) { described_class.create(oid: "2004628", bib: "6805375", barcode: "39002091459793", authoritative_metadata_source_id: voyager) }

      it 'returns source name when authoritative source is set' do
        expect(parent_object.source_name).to eq 'ils'
      end

      it 'returns nil when authoritative source is not set' do
        expect(ParentObject.new(authoritative_metadata_source_id: nil).source_name).to eq nil
      end
    end

    context 'with ladybird_json' do
      let(:parent_object) do
        FactoryBot.build(:parent_object, oid: '16797069', bib: '3435140', barcode: '39002075038423',
                                         ladybird_json: JSON.parse(File.read(File.join(fixture_path, "ladybird", "16797069.json"))))
      end

      it 'returns a ladybird url' do
        expect(parent_object.ladybird_cloud_url).to eq "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/1.0.1/ladybird/oid/16797069?include-children=1"
      end

      it 'returns a voyager url' do
        expect(parent_object.voyager_cloud_url).to eq "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/1.0.1/ils/barcode/39002075038423?bib=3435140"
      end

      it 'returns an aspace url' do
        expect(parent_object.aspace_cloud_url).to eq "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/1.0.1/aspace/repositories/11/archival_objects/608223"
      end

      context "with the wrong metadata_cloud_version set" do
        let(:ladybird_source) { FactoryBot.build(:metadata_source) }
        around do |example|
          original_vpn = ENV['VPN']
          ENV['VPN'] = "true"
          example.run
          ENV['VPN'] = original_vpn
        end
        it "raises an error with wrong version" do
          stub_request(:get, "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/clearly_fake_version/ladybird/oid/16797069?include-children=1")
              .to_return(status: 400, body: File.open(File.join(fixture_path, "metadata_cloud_wrong_version.json")))
          allow(MetadataSource).to receive(:metadata_cloud_version).and_return("clearly_fake_version")
          expect(parent_object.ladybird_cloud_url).to eq "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/clearly_fake_version/ladybird/oid/16797069?include-children=1"
          expect do
            ladybird_source.fetch_record_on_vpn(parent_object)
          end.to raise_error(MetadataSource::MetadataCloudVersionError, "MetadataCloud is not responding to requests for version: clearly_fake_version")
        end
        it "raises an error with 500 response" do
          stub_request(:get, "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/1.0.1/ladybird/oid/16797069?include-children=1")
              .to_return(status: 500, body: { error: "fake error" }.to_json)
          expect(parent_object.ladybird_cloud_url).to eq "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/1.0.1/ladybird/oid/16797069?include-children=1"
          expect do
            ladybird_source.fetch_record_on_vpn(parent_object)
          end.to raise_error(MetadataSource::MetadataCloudServerError, "MetadataCloud is responding with 5XX error")
        end
        it "returns false on out of range response" do
          stub_request(:get, "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/1.0.1/ladybird/oid/16797069?include-children=1")
              .to_return(status: 700, body: { error: "fake error" }.to_json)
          expect(parent_object.ladybird_cloud_url).to eq "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/1.0.1/ladybird/oid/16797069?include-children=1"
          expect(ladybird_source.fetch_record_on_vpn(parent_object)).to be_falsey
        end
        it "returns response" do
          stub_request(:get, "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/1.0.1/ladybird/oid/16797069?include-children=1")
              .to_return(status: 200, body: { data: "fake data" }.to_json)
          expect(parent_object.ladybird_cloud_url).to eq "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/1.0.1/ladybird/oid/16797069?include-children=1"
          allow(S3Service).to receive(:upload).and_return true
          record = ladybird_source.fetch_record(parent_object)
          expect(record['data']).to eq("fake data")
        end
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
        stub_metadata_cloud("100001", "ladybird")
      end
      let(:parent_object) { FactoryBot.create(:parent_object, oid: '100001', authoritative_metadata_source_id: ladybird) }

      it 'returns an empty array' do
        parent_object.reload
        expect(parent_object.child_captions).to be_empty
        expect(parent_object.child_captions).to be_an(Array)
        expect(parent_object.child_labels).to be_empty
        expect(parent_object.child_labels).to be_an(Array)
        expect(parent_object.child_oids).to be_empty
        expect(parent_object.child_oids).to be_an(Array)
      end

      it 'is marked as ready for manifest' do
        expect(parent_object.reload.ready_for_manifest?).to eq true
      end
    end

    context 'with children but no child captions or labels' do
      before do
        stub_metadata_cloud("2012143", "ladybird")
      end
      let(:parent_object) { FactoryBot.create(:parent_object, oid: '2012143', authoritative_metadata_source_id: ladybird) }

      it 'counts the parent objects children' do
        expect(parent_object.reload.child_objects.count).to eq 4
      end

      it 'returns an empty array if the child object has no captions or labels' do
        parent_object.reload
        expect(parent_object.child_captions).to be_an(Array)
        expect(parent_object.child_captions).to be_empty
        expect(parent_object.child_labels).to be_an(Array)
        expect(parent_object.child_labels).to be_empty
        expect(parent_object.child_oids).to be_an(Array)
        expect(parent_object.child_oids).to contain_exactly(1_052_971, 1_052_972, 1_052_973, 1_052_974)
        expect(parent_object.child_oids.size).to eq 4
      end
    end

    context 'with children that have captions and labels' do
      before do
        stub_metadata_cloud("2012143", "ladybird")
        parent_object.child_objects.first.update(caption: "This is a caption")
        parent_object.child_objects.first.update(label: "This is a label")
      end

      let(:parent_object) { FactoryBot.create(:parent_object, oid: '2012143', authoritative_metadata_source_id: ladybird) }
      it "returns an array of the child object's caption and label" do
        expect(parent_object.reload.child_captions).to eq ["This is a caption"]
        expect(parent_object.reload.child_labels).to eq ["This is a label"]
        expect(parent_object.reload.child_oids).to contain_exactly(1_052_971, 1_052_972, 1_052_973, 1_052_974)
      end
      it "returns an array of the child object's captions and labels" do
        parent_object.child_objects.second.update(caption: "This is another caption")
        parent_object.child_objects.second.update(label: "This is another label")

        expect(parent_object.reload.child_captions.size).to eq 2
        expect(parent_object.reload.child_captions).to contain_exactly("This is a caption", "This is another caption")
        expect(parent_object.reload.child_labels.size).to eq 2
        expect(parent_object.reload.child_labels).to contain_exactly("This is a label", "This is another label")
        expect(parent_object.reload.child_oids).to contain_exactly(1_052_971, 1_052_972, 1_052_973, 1_052_974)
      end

      it 'is marked as not ready for manifest unless explicitly told to create one' do
        expect(parent_object.reload.generate_manifest).to eq false
        expect(parent_object.reload.needs_a_manifest?).to eq false
      end
    end
  end

  context "with correct visibility value" do
    let(:parent_object) { described_class.create(oid: "2004628", visibility: 'Public') }
    it 'returns visibility' do
      expect(parent_object.visibility).to eq 'Public'
    end

    it 'returns nil when authoritative source is not set' do
      expect(ParentObject.new(authoritative_metadata_source_id: nil).source_name).to eq nil
    end
  end

  context "chooses correct values for container information" do
    let(:parent_object) { described_class.create(oid: "2004628", visibility: 'Public') }
    it 'returns container grouping if present' do
      expect(parent_object.extract_container_information("containerGrouping" => "container info", "box" => "box 1", "folder" => "folder 1", "volumeEnumeration" => "VE 101")).to eq 'container info'
    end
    it 'returns box, folder if containerGrouping not present' do
      expect(parent_object.extract_container_information("box" => "box 1", "folder" => "folder 1", "volumeEnumeration" => "VE 101")).to eq 'box 1, folder 1'
    end
    it 'returns volumeEnumeration if other fields not present' do
      expect(parent_object.extract_container_information("volumeEnumeration" => "VE 101")).to eq 'VE 101'
    end
  end

  context "a new ParentObject with no info" do
    it "has the expected defaults" do
      po = described_class.new
      expect(po.oid).to be nil
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
end
