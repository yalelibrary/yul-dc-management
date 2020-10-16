# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ParentObject, type: :model, prep_metadata_sources: true do
  let(:ladybird) { 1 }
  let(:voyager) { 2 }
  let(:aspace) { 3 }
  let(:unexpected_metadata_source) { 4 }
  let(:logger_mock) { instance_double("Rails.logger").as_null_object }

  before do
    stub_metadata_cloud("2004628", "ladybird")
    stub_metadata_cloud("2005512", "ladybird")
    stub_metadata_cloud("V-2004628", "ils")
    stub_metadata_cloud("2034600", "ladybird")
    stub_metadata_cloud("16414889")
    stub_metadata_cloud("14716192")
    stub_metadata_cloud("16854285")
    stub_ptiffs
  end

  context "with four child objects" do
    let(:user) { FactoryBot.create(:user) }
    let(:parent_of_four) { FactoryBot.create(:parent_object, oid: 16_057_779) }
    let(:child_of_four) { FactoryBot.create(:child_object, oid: 456_789, parent_object: parent_of_four) }
    let(:batch_process) { FactoryBot.create(:batch_process, user: user) }
    around do |example|
      perform_enqueued_jobs do
        example.run
      end
    end
    # rubocop:disable RSpec/AnyInstance
    it "receives a check for whether it's ready for manifests 4 times, one for each child" do
      allow_any_instance_of(ChildObject).to receive(:parent_object).and_return(parent_of_four)
      parent_of_four.current_batch_process = batch_process
      expect(parent_of_four).to receive(:needs_a_manifest?).exactly(4).times
      parent_of_four.setup_metadata_job
    end
    # rubocop:enable RSpec/AnyInstance
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
      stub_request(:head, "https://yul-dc-development-samples.s3.amazonaws.com/manifests/12/20/05/51/2005512.json")
        .to_return(status: 200)
      stub_request(:head, "https://yul-dc-development-samples.s3.amazonaws.com/manifests/89/16/41/48/89/16414889.json")
        .to_return(status: 200)
      stub_request(:head, "https://yul-dc-development-samples.s3.amazonaws.com/manifests/92/14/71/61/92/14716192.json")
        .to_return(status: 200)
      stub_request(:head, "https://yul-dc-development-samples.s3.amazonaws.com/manifests/85/16/85/42/85/16854285.json")
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
      parent_object.current_batch_process = batch_process
      expect do
        batch_process.file = csv_upload
        batch_process.run_callbacks :create
      end.to change { batch_process.batch_connections.size }.from(0).to(5)
      expect(user_one.notifications.count).to eq(238)
      statuses = Notification.all.map { |note| note.params[:status] }
      expect(statuses).to include "processing-queued"
      expect(statuses).to include "metadata-fetched"
      expect(statuses).to include "child-records-created"
      expect(statuses).to include "ptiff-ready"
      expect(statuses).to include "manifest-saved"
      expect(statuses).to include "solr-indexed"
      expect(Notification.all.map { |note| note.params[:reason] }).to include "Processing has been queued"
      expect(Notification.count).to eq(714)
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

    let(:parent_object_public) { described_class.create(oid: "2005512", visibility: "Public") }
    it "Public visibility does validate" do
      expect(parent_object_public.valid?).to eq true
      expect(parent_object_public.visibility).to eq "Public"
    end
  end

  context "a newly created ParentObject with an unexpected authoritative_metadata_source" do
    let(:unexpected_metadata_source) { FactoryBot.create(:metadata_source, id: 4, metadata_cloud_name: "foo", display_name: "Foo", file_prefix: "F-") }
    let(:parent_object) { FactoryBot.create(:parent_object, oid: "2004628", authoritative_metadata_source: unexpected_metadata_source) }
    it "raises an error when trying to get the authoritative_json for an unexpected metadata source" do
      expect { parent_object.authoritative_json }.to raise_error(StandardError)
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
      let(:parent_object) { described_class.create(oid: "2005512") }
      before do
        stub_metadata_cloud("2005512", "ladybird")
        stub_metadata_cloud("V-2005512", "ils")
      end
      it "pulls from the MetadataCloud for Ladybird and not Voyager or ArchiveSpace" do
        expect(parent_object.reload.authoritative_metadata_source_id).to eq ladybird
        expect(parent_object.ladybird_json).not_to be nil
        expect(parent_object.ladybird_json).not_to be_empty
        expect(parent_object.voyager_json).to be nil
        expect(parent_object.aspace_json).to be nil
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
    end

    context "a newly created ParentObject with Voyager as authoritative_metadata_source" do
      let(:parent_object) { described_class.create(oid: "2004628", authoritative_metadata_source_id: voyager) }

      it "pulls from the MetadataCloud for Ladybird and Voyager and not ArchiveSpace" do
        expect(parent_object.reload.authoritative_metadata_source_id).to eq voyager
        expect(parent_object.ladybird_json).not_to be nil
        expect(parent_object.ladybird_json).not_to be_empty
        expect(parent_object.voyager_json).not_to be nil
        expect(parent_object.voyager_json).not_to be_empty
        expect(parent_object.aspace_json).to be nil
      end

      it "can return the json from its authoritative_metadata_source" do
        expect(parent_object.authoritative_json).to eq parent_object.voyager_json
      end
    end

    context "a newly created ParentObject with ArchiveSpace as authoritative_metadata_source" do
      let(:parent_object) { described_class.create(oid: "2012036", authoritative_metadata_source_id: aspace) }
      before do
        stub_metadata_cloud("2012036", "ladybird")
        stub_metadata_cloud("AS-2012036", "aspace")
      end

      it "pulls from the MetadataCloud for Ladybird and ArchiveSpace and not Voyager" do
        expect(parent_object.reload.authoritative_metadata_source_id).to eq aspace # 3 is ArchiveSpace
        expect(parent_object.ladybird_json).not_to be nil
        expect(parent_object.ladybird_json).not_to be_empty
        expect(parent_object.aspace_json).not_to be nil
        expect(parent_object.aspace_json).not_to be_empty
        expect(parent_object.voyager_json).to be nil
      end
    end

    context "has a shortcut for the metadata_cloud_name" do
      let(:parent_object) { described_class.create(oid: "2004628", authoritative_metadata_source_id: voyager) }
      it 'returns source name when authoritative source is set' do
        expect(parent_object.source_name).to eq 'ils'
      end

      it 'returns nil when authoritative source is not set' do
        expect(ParentObject.new(authoritative_metadata_source_id: nil).source_name).to eq nil
      end
    end

    context 'with ladybird_json' do
      let(:parent_object) { FactoryBot.build(:parent_object, oid: '16797069', ladybird_json: JSON.parse(File.read(File.join(fixture_path, "ladybird", "16797069.json")))) }

      it 'returns a ladybird url' do
        expect(parent_object.ladybird_cloud_url).to eq "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/ladybird/oid/16797069?include-children=1"
      end

      it 'returns a voyager url' do
        expect(parent_object.voyager_cloud_url).to eq "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/ils/barcode/39002075038423?bib=3435140"
      end

      it 'returns an aspace url' do
        expect(parent_object.aspace_cloud_url).to eq "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/aspace/repositories/11/archival_objects/608223"
      end
    end

    context 'with ladybird_json but no orbisBarcode' do
      let(:parent_object) { FactoryBot.build(:parent_object, oid: '16712419', ladybird_json: JSON.parse(File.read(File.join(fixture_path, "ladybird", "16712419.json")))) }

      it 'returns a voyager url using the bib' do
        expect(parent_object.voyager_cloud_url).to eq "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/ils/bib/1289001"
      end
    end

    context 'without ladybird_json' do
      let(:parent_object) { FactoryBot.build(:parent_object, oid: '16797069') }

      it 'returns a voyager url' do
        expect(parent_object.voyager_cloud_url).to eq nil
      end

      it 'returns an aspace url' do
        expect(parent_object.aspace_cloud_url).to eq nil
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
      expect(po.reading_direction).to be nil
      expect(po.pagination).to be nil
      expect(po.child_object_count).to be nil
      expect(po.authoritative_metadata_source_id).to eq ladybird
    end
  end
end
