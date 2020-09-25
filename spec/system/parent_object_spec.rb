# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "ParentObjects", type: :system, prep_metadata_sources: true do
  let(:user) { FactoryBot.create(:user) }
  before do
    stub_ptiffs_and_manifests
    login_as user
  end
  around do |example|
    perform_enqueued_jobs do
      example.run
    end
  end
  context "creating a new ParentObject based on oid" do
    before do
      visit parent_objects_path
      click_on("New Parent Object")
    end

    context "with a ParentObject whose authoritative_metadata_source is Ladybird" do
      before do
        stub_metadata_cloud("2012036")
        fill_in('Oid', with: "2012036")
        click_on("Create Parent object")
      end

      it "can create a new parent object" do
        expect(page.body).to include "Parent object was successfully created"
        expect(page.body).to include "Ladybird"
        expect(page.body).to include "Authoritative JSON"
      end

      it "saves the Ladybird record from the MC to the DB" do
        po = ParentObject.find_by(oid: "2012036")
        expect(po.ladybird_json).not_to be nil
        expect(po.ladybird_json).not_to be_empty
      end

      it "has the ids from the Ladybird record" do
        po = ParentObject.find_by(oid: "2012036")
        expect(po.bib).to eq "6805375"
        expect(po.barcode).to eq "39002091459793"
        expect(po.aspace_uri).to eq "/repositories/11/archival_objects/555049"
        expect(po.visibility).to eq "Public"
      end
    end

    context "with a ParentObject whose authoritative_metadata_source is Voyager" do
      before do
        stub_metadata_cloud("2012036", "ladybird")
        stub_metadata_cloud("V-2012036", "ils")
        fill_in('Oid', with: "2012036")
        select('Voyager')
        click_on("Create Parent object")
      end

      it "can create a new parent object" do
        expect(page.body).to include "Parent object was successfully created"
        expect(page.body).to include "Voyager"
      end

      it "has the correct authoritative_metadata_source in the database" do
        po = ParentObject.find_by(oid: "2012036")
        expect(po.authoritative_metadata_source_id).to eq 2
      end

      it "has the record and ids from the Voyager record" do
        po = ParentObject.find_by(oid: "2012036")
        expect(po.voyager_json).not_to be nil
        expect(po.voyager_json).not_to be_empty
        expect(po.holding).to eq "7397126"
        expect(po.item).to eq "8200460"
      end
    end

    context "with a ParentObject whose authoritative_metadata_source is ArchiveSpace" do
      before do
        stub_metadata_cloud("2012036", "ladybird")
        stub_metadata_cloud("AS-2012036", "aspace")
        fill_in('Oid', with: "2012036")
        select('ArchiveSpace')
        click_on("Create Parent object")
      end

      it "can create a new parent object" do
        expect(page.body).to include "Parent object was successfully created"
        expect(page.body).to include "ArchiveSpace"
      end

      it "fetches the ArchiveSpace record when applicable" do
        po = ParentObject.find_by(oid: "2012036")
        expect(po.aspace_json).not_to be nil
        expect(po.aspace_json).not_to be_empty
      end
    end

    context "with a ParentObject with only some relevant identifiers" do
      before do
        stub_metadata_cloud("2004628", "ladybird")
        stub_metadata_cloud("V-2004628", "ils")
        fill_in('Oid', with: "2004628")
        click_on("Create Parent object")
      end

      it "can create a new parent object" do
        expect(page.body).to include "Parent object was successfully created"
      end

      it "leaves empty values as nil" do
        expect(ParentObject.find_by(oid: "2004628")["barcode"].nil?).to be true
        expect(ParentObject.find_by(oid: "2004628")["aspace_uri"].nil?).to be true
      end

      it "still fills in non-empty values" do
        expect(ParentObject.find_by(oid: "2004628")["bib"]).to eq "3163155"
      end
    end

    context "with a ParentObject whose authoritative_metadata_source is Voyager" do
      before do
        stub_metadata_cloud("2012036", "ladybird")
        stub_metadata_cloud("V-2012036", "ils")
        fill_in('Oid', with: "2012036")
        select('Public')
        click_on("Create Parent object")
      end

      it "can create a new parent object" do
        expect(page.body).to include "Parent object was successfully created"
        expect(page.body).to include "Public"
      end

      it "adds the visibility for public objects" do
        expect(ParentObject.find_by(oid: "2012036")["visibility"]).to eq "Public"
      end
    end

    context "with mocked out non-public objects" do
      around do |example|
        original_vpn = ENV['VPN']
        ENV['VPN'] = 'false'
        example.run
        ENV['VPN'] = original_vpn
      end
      context "with a Private fixture object" do
        before do
          stub_metadata_cloud("10000016189097", "ladybird")
          stub_metadata_cloud("V-10000016189097", "ils")
          fill_in('Oid', with: "10000016189097")
          click_on("Create Parent object")
        end
        it "adds the visibility for private objects" do
          expect(ParentObject.find_by(oid: "10000016189097")["visibility"]).to eq "Private"
        end
      end

      context "with a Yale only fixture object" do
        before do
          stub_metadata_cloud("20000016189097", "ladybird")
          stub_metadata_cloud("V-20000016189097", "ils")
          fill_in('Oid', with: "20000016189097")
          click_on("Create Parent object")
        end
        it "adds the visibility for non-public objects" do
          expect(ParentObject.find_by(oid: "20000016189097")["visibility"]).to eq "Yale Community Only"
        end
      end
    end
  end
end
