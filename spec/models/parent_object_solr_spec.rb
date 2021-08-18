# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ParentObject, type: :model, prep_metadata_sources: true, solr: true do
  # this doesn't seem to run from a helper, not clear why
  around do |example|
    perform_enqueued_jobs do
      original_path_ocr = ENV['OCR_DOWNLOAD_BUCKET']
      ENV['OCR_DOWNLOAD_BUCKET'] = "yul-dc-ocr-test"
      example.run
      ENV['OCR_DOWNLOAD_BUCKET'] = original_path_ocr
    end
  end

  before do
    stub_ptiffs_and_manifests
    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(ParentObject).to receive(:manifest_completed?).and_return(true)
    # rubocop:enable RSpec/AnyInstance
    stub_full_text('1032318')
  end

  describe "ParentObject without some values for solr mapping" do
    let(:oid) { "2034600" }
    let(:parent_object) { FactoryBot.create(:parent_object, oid: oid, source_name: 'ladybird', visibility: "Public") }
    before do
      stub_metadata_cloud(oid)
      parent_object
    end
    it "does not have null values in to_solr hash" do
      solr_document = parent_object.reload.to_solr
      expect(solr_document.values).not_to include(nil)
    end

    it "does not have empty strings in to_solr hash" do
      parent_object.bib = ""
      parent_object.save!
      solr_document = parent_object.reload.to_solr
      expect(solr_document.values).not_to include("")
    end

    it "will index the count of child objects" do
      solr_document = parent_object.reload.to_solr
      expect(solr_document[:imageCount_isi]).to eq 1
    end

    it "can index a thumbnail path to Solr" do
      solr_document = parent_object.reload.to_solr
      expect(solr_document[:thumbnail_path_ss]).to eq "http://localhost:8182/iiif/2/1126257/full/!200,200/0/default.jpg"
    end
  end

  describe "changing the authoritative metadata source", solr: true do
    let(:oid) { "2034600" }
    let(:parent_object) { FactoryBot.create(:parent_object, oid: oid, source_name: 'ladybird', visibility: "Public") }
    before do
      stub_metadata_cloud(oid)
      parent_object
    end
    it "indexes the ladybird_json then overwrites with the Voyager json" do
      solr_document = parent_object.reload.to_solr
      expect(solr_document[:title_tesim]).to eq ["[Magazine page with various photographs of Leontyne Price]"]
      parent_object.source_name = "ils"
      parent_object.save!
      solr_document = parent_object.reload.to_solr
      expect(solr_document[:title_tesim]).to eq ["Ebony"]
      response = solr.get 'select', params: { q: 'type_ssi:parent' }
      expect(response["response"]["numFound"]).to eq 1
    end
  end

  context "indexing to Solr from the database with Ladybird ParentObjects", solr: true do
    it "can index the 5 parent objects in the database to Solr and can remove those items" do
      response = solr.get 'select', params: { q: 'type_ssi:parent' }
      existing_solr_count = response["response"]["numFound"].to_i

      expect do
        [
          '2034600',
          '2005512',
          '16414889',
          '14716192',
          '16854285'
        ].each do |oid|
          stub_metadata_cloud(oid)
          FactoryBot.create(:parent_object, oid: oid)
        end
      end.to change { ParentObject.count }.by(5)

      response = solr.get 'select', params: { q: 'type_ssi:parent' }
      expect(response["response"]["numFound"]).to eq(5 + existing_solr_count)

      expect(SolrService.delete_all).to be
      response = solr.get 'select', params: { q: '*:*' }
      expect(response["response"]["numFound"]).to eq 0
    end

    it "can reindex all the parent objects in a background job" do
      response = solr.get 'select', params: { q: 'type_ssi:parent' }
      expect(response["response"]["numFound"]).to eq 0

      expect do
        [
          '2034600',
          '2005512',
          '16414889',
          '14716192',
          '16854285'
        ].each do |oid|
          stub_metadata_cloud(oid)
          FactoryBot.create(:parent_object, oid: oid)
        end
      end.to change { ParentObject.count }.by(5)
      expect(SolrReindexAllJob.perform_now).to be
      response = solr.get 'select', params: { q: 'type_ssi:parent' }
      expect(response["response"]["numFound"]).to eq 5
    end

    it 'can remove an item from Solr' do
      response = solr.get 'select', params: { q: 'type_ssi:parent' }
      expect(response["response"]["numFound"]).to eq 0

      expect do
        [
          '2034600'
        ].each do |oid|
          stub_metadata_cloud(oid)
          FactoryBot.create(:parent_object, oid: oid)
        end
      end.to change { ParentObject.count }.by(1)
      response = solr.get 'select', params: { q: 'type_ssi:parent' }
      expect(response["response"]["numFound"]).to eq 1

      expect do
        [
          '2034600'
        ].each do |oid|
          ParentObject.find(oid).destroy
        end
      end.to change { ParentObject.count }.by(-1)

      response = solr.get 'select', params: { q: 'type_ssi:parent' }
      expect(response["response"]["numFound"]).to eq 0
    end
  end

  context "with Archival fixture data" do
    let(:oid) { "2005512" }
    let(:metadata_source) { "aspace" }
    let(:id_prefix) { "AS-" }

    context "with a public item" do
      let(:parent_object_with_public_visibility) { FactoryBot.create(:parent_object, oid: oid, bib: "4113177", barcode: "39002093768050", source_name: metadata_source, visibility: "Public") }
      around do |example|
        original_image_url = ENV['IIIF_IMAGE_BASE_URL']
        ENV['IIIF_IMAGE_BASE_URL'] = "http://localhost:8182/iiif"
        example.run
        ENV['IIIF_IMAGE_BASE_URL'] = original_image_url
      end
      before do
        stub_metadata_cloud(oid.to_s)
        stub_metadata_cloud("AS-#{oid}", "aspace")
      end

      it "can create a Solr document for a record, including visibility" do
        solr_document = parent_object_with_public_visibility.reload.to_solr
        expect(solr_document[:repository_ssi]).to eq "Beinecke Rare Book and Manuscript Library (BRBL)"
        expect(solr_document[:archivalSort_ssi]).to include "00002.00000"
        expect(solr_document[:ancestorTitles_tesim]).to include "Oversize",
                                                                "Abraham Lincoln collection (GEN MSS 257)",
                                                                "Beinecke Rare Book and Manuscript Library (BRBL)"
        expect(solr_document[:ancestor_titles_hierarchy_ssim].first).to eq "Beinecke Rare Book and Manuscript Library (BRBL) > "
        expect(solr_document[:ancestor_titles_hierarchy_ssim][1]).to eq "Beinecke Rare Book and Manuscript Library (BRBL) > Abraham Lincoln collection (GEN MSS 257) > "
        expect(solr_document[:ancestor_titles_hierarchy_ssim].last).to eq "Beinecke Rare Book and Manuscript Library (BRBL) > Abraham Lincoln collection (GEN MSS 257) > Oversize > "
        expect(solr_document[:collection_title_ssi]).to include "Abraham Lincoln collection (GEN MSS 257)"
        expect(solr_document[:ancestorDisplayStrings_tesim]).to include "Oversize, n.d.",
                                                                        "Abraham Lincoln collection",
                                                                        "Beinecke Rare Book and Manuscript Library (BRBL)"
      end
    end
  end

  context "with Voyager fixture data" do
    let(:oid) { "2012036" }
    let(:metadata_source) { "ils" }
    let(:id_prefix) { "V-" }

    context "with a public item" do
      let(:parent_object_with_public_visibility) { FactoryBot.create(:parent_object, oid: oid, bib: "6805375", barcode: "39002091459793", source_name: 'ils', visibility: "Public") }
      around do |example|
        original_image_url = ENV['IIIF_IMAGE_BASE_URL']
        ENV['IIIF_IMAGE_BASE_URL'] = "http://localhost:8182/iiif"
        example.run
        ENV['IIIF_IMAGE_BASE_URL'] = original_image_url
      end
      before do
        stub_metadata_cloud(oid.to_s)
        stub_metadata_cloud("V-#{oid}", "ils")
        stub_metadata_cloud("AS-#{oid}", "aspace")
      end

      it "can create a Solr document for a record, including visibility" do
        solr_document = parent_object_with_public_visibility.reload.to_solr
        expect(solr_document[:title_tsim]).to eq ["Walt Whitman collection, 1842-1949"]
        expect(solr_document[:visibility_ssi]).to include "Public"
      end
    end

    context "with mocked items without a metadatacloud equivalent" do
      around do |example|
        original_vpn = ENV['VPN']
        ENV['VPN'] = 'false'
        example.run
        ENV['VPN'] = original_vpn
      end

      context "with a private item" do
        let(:priv_oid) { "10000016189097" }
        let(:parent_object_with_private_visibility) { FactoryBot.create(:parent_object, oid: priv_oid, visibility: "Private", source_name: 'ils') }

        before do
          stub_metadata_cloud(priv_oid)
          stub_metadata_cloud("V-#{priv_oid}", 'ils')
        end

        it "assigns private visibility from Ladybird data" do
          solr_document = parent_object_with_private_visibility.reload.to_solr
          expect(solr_document[:title_tsim].first).to include "Dai Min kyūhen bankoku jinseki rotei zenzu"
          expect(solr_document[:visibility_ssi]).to include "Private"
        end
      end
    end

    describe "changing the visibility" do
      let(:oid) { "2034600" }
      let(:parent_object) { FactoryBot.create(:parent_object, oid: oid, source_name: 'ladybird') }
      it "commits data to solr if it is changed on the object" do
        expect do
          parent_object.setup_metadata_job
          perform_enqueued_jobs
          parent_object.reload
        end.to change(parent_object, :visibility).from("Private").to("Public")

        expect do
          parent_object.visibility = "Yale Community Only"
          parent_object.bib = "123321xx"
          parent_object.call_number = "JWJ A +Eb74"
          parent_object.child_object_count = 985_555
          parent_object.barcode = "3200000000000"
          parent_object.aspace_uri = "/repository/12345/archiveobject/566666"
          parent_object.holding = "555555555"
          parent_object.item = "33333333333"
          parent_object.viewing_direction = "left to right"
          parent_object.display_layout = "book"
          parent_object.save!
          parent_object.reload
        end.to change(parent_object, :visibility).from("Public").to("Yale Community Only")
           .and change(parent_object, :holding).from(nil).to("555555555")
           .and change(parent_object, :item).from(nil).to("33333333333")
           .and change(parent_object, :viewing_direction).from(nil).to("left to right")
           .and change(parent_object, :display_layout).from(nil).to("book")
        response = solr.get 'select', params: { q: 'oid_ssi:2034600' }
        expect(response["response"]["docs"].first["visibility_ssi"]).to eq "Yale Community Only"
        expect(response["response"]["docs"].first["orbisBibId_ssi"]).to eq "123321xx"
        expect(response["response"]["docs"].first["imageCount_isi"]).to eq 985_555
        expect(response["response"]["docs"].first["orbisBarcode_ssi"]).to eq "3200000000000"
        expect(response["response"]["docs"].first["archiveSpaceUri_ssi"]).to eq "/repository/12345/archiveobject/566666"
      end
    end
  end

  describe "expand_date_structured" do
    let(:oid) { "2034600" }
    let(:parent_object) { described_class.new }
    it "expands dates with explicit ranges" do
      expect(parent_object.expand_date_structured(["2000/2005"])).to eq [2000, 2001, 2002, 2003, 2004, 2005]
    end
    it "expands dates with open ended ranges" do
      expected_result = (2000..Time.now.utc.year).to_a
      expect(parent_object.expand_date_structured(["2000/9999"])).to eq expected_result
    end
    it "expands dates without ranges" do
      expect(parent_object.expand_date_structured(["2000", "2010"])).to eq [2000, 2010]
    end
    it "expands empty array to empty array" do
      expect(parent_object.expand_date_structured([])).to eq []
    end
    it "expands nil to nil" do
      expect(parent_object.expand_date_structured(nil)).to eq nil
    end
    it "returns nil if not an array" do
      expect(parent_object.expand_date_structured("non-array")).to eq nil
      expect(parent_object.expand_date_structured("1995")).to eq nil
      expect(parent_object.expand_date_structured(parent_object)).to eq nil
    end
    it "expands range and non-ranges combined" do
      expect(parent_object.expand_date_structured(["2000/2004", "1945"])).to eq [1945, 2000, 2001, 2002, 2003, 2004]
    end
    it "expands overlapping ranges with dedup" do
      expect(parent_object.expand_date_structured(["2000/2004", "1945", "2002/2006"])).to eq [1945, 2000, 2001, 2002, 2003, 2004, 2005, 2006]
    end
    it "dedups non-range values" do
      expect(parent_object.expand_date_structured(["1945", "2002", "1945"])).to eq [1945, 2002]
    end
    it "responds correctly with invalid ranges" do
      expect(parent_object.expand_date_structured(["1945/1935"])).to eq []
      expect(parent_object.expand_date_structured(["9999/1935"])).to eq []
      expect(parent_object.expand_date_structured(["9999/1935", "1955"])).to eq [1955]
      expect(parent_object.expand_date_structured(["1935/2021/1953", "1975"])).to eq [1975]
    end
  end
end
