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

    context "setting non-required values" do
      before do
        stub_metadata_cloud("2012036")
        fill_in('Oid', with: "2012036")
      end

      it "includes reference to documentation for IIIF values" do
        expect(page).to have_link("IIIF viewing direction details", href: "https://iiif.io/api/presentation/2.1/#viewingdirection")
        expect(page).to have_link("IIIF viewing hints details", href: "https://iiif.io/api/presentation/2.1/#viewinghint")
      end

      it "includes fields that are not editable" do
        expect(page).to have_field("Oid", disabled: false)
      end

      it "can set iiif values via the UI" do
        page.select("left-to-right", from: "Viewing direction")
        page.select("continuous", from: "Display layout")
        click_on("Create Parent object")
        expect(page.body).to include "Parent object was successfully created"
        expect(page.body).to include "left-to-right"
        expect(page.body).to include "continuous"
      end

      it "can show the representative thumbnail via the UI" do
        click_on("Create Parent object")
        expect(page).to have_content("Children:")
        expect(page).to have_content("1052760")
        expect(page).to have_content("Representative thumbnail")
      end

      it "can select a different representative thumbnail via the UI" do
        click_on("Create Parent object")
        click_on("Edit")
        expect(page).to have_link("Select different representative thumbnail")
        click_on("Select different representative thumbnail")
        expect(page).to have_css("#parent_object_representative_child_oid_1052761")
        page.find("#parent_object_representative_child_oid_1052761").choose
        click_on("Update Parent object")
        expect(ParentObject.find(2_012_036).representative_child_oid).to eq 1_052_761
      end

      it "can see number of child objects on the index page" do
        click_on("Create Parent object")
        click_on("Back")
        expect(page).to have_content "Child object count"
      end
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

      it "has a batch process (of one)" do
        po = ParentObject.find_by(oid: "2012036")
        expect(po.batch_connections.count).to eq 1
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
        expect(page.body).to include "Public"
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

      it "adds the visibility for public objects" do
        expect(ParentObject.find_by(oid: "2012036")["visibility"]).to eq "Public"
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

  context "editing a ParentObject" do
    let(:parent_object) { FactoryBot.create(:parent_object, oid: 2_012_036) }
    before do
      stub_metadata_cloud("2012036")
      parent_object
      visit edit_parent_object_path(2_012_036)
    end

    it "can see non-editable fields" do
      expect(page).to have_field("Oid", disabled: true)
    end
  end
end
