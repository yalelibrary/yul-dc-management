# frozen_string_literal: true
require 'rails_helper'

UPDATE_PARENT_OBJECT_BUTTON = 'Save Parent Object And Update Metadata'

RSpec.describe "ParentObjects", type: :system, prep_metadata_sources: true, prep_admin_sets: true do
  let(:user) { FactoryBot.create(:sysadmin_user) }
  before do
    stub_ptiffs_and_manifests
    login_as user
  end
  around do |example|
    perform_enqueued_jobs do
      original_path_ocr = ENV['OCR_DOWNLOAD_BUCKET']
      ENV['OCR_DOWNLOAD_BUCKET'] = "yul-dc-ocr-test"
      example.run
      ENV['OCR_DOWNLOAD_BUCKET'] = original_path_ocr
    end
  end
  context "a parent object with an extent of digitization" do
    before do
      visit "parent_objects/new"
      stub_metadata_cloud("10001192")
      fill_in('Oid', with: "10001192")
      select('Beinecke Library')
      select('Ladybird')
    end

    it "sets the expected fields in the database" do
      click_on("Create Parent object")
      po = ParentObject.find(10_001_192)
      expect(po.oid).to eq 10_001_192
      expect(po.bib).to eq "3659107"
      expect(po.call_number).to eq "GEN MSS 963"
      expect(po.holding).to be_empty
      expect(po.item).to be_empty
      expect(po.barcode).to eq "39002091548348"
      expect(po.visibility).to eq "Public"
      expect(po.child_object_count).to eq 2
      expect(po.representative_child_oid).to be nil
      expect(po.rights_statement).to include "The use of this image may be subject to the copyright law"
      expect(po.extent_of_digitization).to eq "Completely digitized"
    end

    it "can update the extent of digitization" do
      click_on("Create Parent object")
      click_on("Edit")
      page.select("Partially digitized", from: "Extent of digitization")
      click_on("Save Parent Object And Update Metadata")
      expect(page).to have_content("Partially digitized")
    end
  end

  context "creating a new ParentObject based on oid" do
    before do
      visit "parent_objects/new"
    end

    context "setting non-required values" do
      before do
        stub_metadata_cloud("2012036")
        fill_in('Oid', with: "2012036")
        select('Beinecke Library')
        select('Ladybird')
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

      it "can set the rights statement via the UI" do
        click_on("Create Parent object")
        click_on("Edit")
        expect(page).to have_field("Rights statement")
        fill_in("Rights statement", with: "This is a rights statement")
        click_on(UPDATE_PARENT_OBJECT_BUTTON)
        expect(page).to have_content("This is a rights statement")
      end

      it "can set the Project ID via the UI" do
        click_on("Create Parent object")
        click_on("Edit")
        expect(page).to have_field("Project ID")
        fill_in("Project ID", with: "This is the Project ID")
        click_on(UPDATE_PARENT_OBJECT_BUTTON)
        expect(page).to have_content("This is the Project ID")
      end

      it "can set the Preservica Representation Name via the UI" do
        click_on("Create Parent object")
        click_on("Edit")
        expect(page).to have_field("Preservica representation name")
        fill_in("Preservica representation name", with: "Access-1")
        click_on(UPDATE_PARENT_OBJECT_BUTTON)
        expect(page).to have_content("Access-1")
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
        expect(page).to have_content "Child Object Count"
      end

      it "validates preservica uri based on digital object source presence" do
        select('Preservica')
        click_on("Create Parent object")
        expect(page).to have_content "Preservica uri can't be blank"
        expect(page).to have_content "Preservica uri in incorrect format. URI must start with a /"
      end

      it "validates preservica uri format" do
        select('Preservica')
        expect(page).to have_field("Preservica uri")
        fill_in('Preservica uri', with: "/preservica_uri")
        click_on("Create Parent object")
        expect(page).to have_content '/preservica_uri'
      end
    end

    context "with a ParentObject whose authoritative_metadata_source is Ladybird" do
      before do
        stub_metadata_cloud("2012036")
        fill_in('Oid', with: "2012036")
        select("Beinecke Library")
        select('Ladybird')
        click_on("Create Parent object")
      end

      around do |example|
        perform_enqueued_jobs do
          example.run
        end
      end

      it "can create a new parent object" do
        expect(page.body).to include "Parent object was successfully created"
        expect(page.body).to include "Ladybird"
        expect(page.body).to include "Authoritative JSON"
        expect(page.body).to include "Public"
        expect(page.body).to include "MetadataCloud url"
      end

      it "can change the visibility via the UI" do
        click_on("Edit")
        select("Yale Community Only")
        click_on(UPDATE_PARENT_OBJECT_BUTTON)
        expect(page.body).to include "Yale Community Only"
        click_on("Back")
        click_on("Update Metadata")
        visit parent_object_path(2_012_036)
        expect(page.body).to include "Yale Community Only"
      end

      it "can change the visibility to private via the UI" do
        click_on("Edit")
        select("Yale Community Only")
        click_on(UPDATE_PARENT_OBJECT_BUTTON)
        expect(page.body).to include "Yale Community Only"
        click_on("Edit")
        select("Private")
        click_on(UPDATE_PARENT_OBJECT_BUTTON)
        expect(page.body).to include "Private"
        click_on("Back")
        click_on("Update Metadata")
        visit parent_object_path(2_012_036)
        # counts once on page and once in solr document section
        expect(page.body).to include("Private").twice
        expect(page.body).to include "visibility_ssi"
      end

      it "can change the Admin Set via the UI", prep_admin_sets: true do
        visit parent_object_path(2_012_036)
        click_on("Edit")
        select 'Sterling', from: "parent_object[admin_set]"
        click_on(UPDATE_PARENT_OBJECT_BUTTON)

        visit parent_object_path(2_012_036)
        expect(page).to have_content "Sterling"
      end

      it "includes the rights statment" do
        within("div.rights-statement") do
          expect(page).to have_content("The use of this image may be subject to the")
        end
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

      it 'has functioning Solr Document link' do
        expect(page).to have_link("Solr Document", href: solr_document_parent_object_path("2012036"))
        click_on("Solr Document")
        solr_data = JSON.parse(page.body)
        expect(solr_data['numFound']).to eq 1
        expect(solr_data["docs"].count).to eq 1
        document = solr_data["docs"].first
        expect(document["id"]).to eq "2012036"
        expect(document["callNumber_tesim"]).to include "YCAL MSS 202"
        expect(document["dateStructured_ssim"]).not_to be
      end

      it 'has a Public View link' do
        po = ParentObject.find_by(oid: "2012036")
        expect(page).to have_link("Public View", href: po.dl_show_url)
      end

      it 'shows error if creating parent with oid that exists' do
        visit new_parent_object_path
        fill_in('Oid', with: "2012036")
        select("Beinecke Library")
        click_on("Create Parent object")
        expect(page.body).to include "The oid already exists"
        expect(page).to have_current_path(new_parent_object_path)
      end
    end

    context "with a ParentObject whose authoritative_metadata_source is Ladybird" do
      before do
        stub_metadata_cloud("2005512")
        fill_in('Oid', with: "2005512")
        select('Ladybird')
        click_on("Create Parent object")
      end

      around do |example|
        perform_enqueued_jobs do
          example.run
        end
      end

      it 'shows error if creating parent with no admin set' do
        expect(page.body).to include "Admin set is required to create parent object"
        expect(page).to have_current_path(new_parent_object_path)
      end
    end

    context "with a ParentObject whose authoritative_metadata_source is Voyager" do
      before do
        stub_metadata_cloud("2012036", "ladybird")
        stub_metadata_cloud("V-2012036", "ils")
        fill_in('Oid', with: "2012036")
        fill_in('Bib', with: "6805375")
        fill_in('Barcode', with: "39002091459793")
        select('Public')
        select('Voyager')
        select('Beinecke Library')
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

      it 'has functioning Solr Document link' do
        po = ParentObject.find_by(oid: "2012036")
        po.solr_index_job
        expect(page).to have_link("Solr Document", href: solr_document_parent_object_path("2012036"))
        click_on("Solr Document")
        solr_data = JSON.parse(page.body)
        expect(solr_data['numFound']).to eq 1
        expect(solr_data["docs"].count).to eq 1
        document = solr_data["docs"].first
        expect(document["id"]).to eq "2012036"
        expect(document["callNumber_tesim"]).to include "YCAL MSS 202"
        expect(document["dateStructured_ssim"]).to eq ["1842/1949"]
        expect(document["year_isim"]).to include 1845
      end
    end

    context "with a ParentObject whose authoritative_metadata_source is ArchiveSpace" do
      around do |example|
        original_vpn = ENV['VPN']
        ENV['VPN'] = 'false'
        example.run
        ENV['VPN'] = original_vpn
      end

      before do
        stub_metadata_cloud("2012036", "ladybird")
        stub_metadata_cloud("AS-2012036", "aspace")
        fill_in('Oid', with: "2012036")
        fill_in('parent_object_aspace_uri', with: "/repositories/11/archival_objects/555049")
        select('ArchiveSpace')
        select('Beinecke Library')
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

      it 'has functioning Solr Document link' do
        po = ParentObject.find_by(oid: "2012036")
        po.solr_index_job
        expect(page).to have_link("Solr Document", href: solr_document_parent_object_path("2012036"))
        click_on("Solr Document")
        solr_data = JSON.parse(page.body)
        expect(solr_data['numFound']).to eq 1
        expect(solr_data["docs"].count).to eq 1
        document = solr_data["docs"].first
        expect(document["id"]).to eq "2012036"
        expect(document["localRecordNumber_ssim"]).to include "YCAL MSS 202"
      end
    end

    context "with a ParentObject with only some relevant identifiers" do
      before do
        stub_metadata_cloud("2004628", "ladybird")
        stub_metadata_cloud("V-2004628", "ils")
        fill_in('Oid', with: "2004628")
        select('Beinecke Library')
        select('Ladybird')
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
          select("Beinecke Library")
          select("Ladybird")
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
          select("Beinecke Library")
          select('Ladybird')
          click_on("Create Parent object")
        end
        it "adds the visibility for non-public objects" do
          expect(ParentObject.find_by(oid: "20000016189097")["visibility"]).to eq "Yale Community Only"
        end
      end
    end
  end

  context "editing a ParentObject" do
    let(:parent_object) { FactoryBot.create(:parent_object, oid: 2_012_036, admin_set: AdminSet.find_by_key('brbl')) }
    before do
      stub_metadata_cloud("2012036")
      parent_object
      visit edit_parent_object_path(2_012_036)
    end

    it "can see non-editable fields" do
      expect(page).to have_field("Oid", disabled: true)
    end
  end

  describe "index page", js: true do
    context 'datatable' do
      let(:parent_object1) { FactoryBot.create(:parent_object, oid: 2_034_600, admin_set: AdminSet.find_by_key('brbl')) }
      let(:parent_object2) { FactoryBot.create(:parent_object, oid: 2_005_512, admin_set: AdminSet.find_by_key('brbl')) }

      before do
        stub_metadata_cloud('2034600')
        stub_metadata_cloud('2005512')
        parent_object1
        parent_object2
        visit parent_objects_path
      end

      it 'has multiple Parent Objects' do
        within '#parent-objects-datatable' do
          expect(page).to have_xpath '//*[@id="2034600"]/td[@class="sorting_1"]/a[1]', text: '2034600'
          expect(page).to have_xpath '//*[@id="2005512"]/td[@class="sorting_1"]/a[1]', text: '2005512'
        end
      end
    end

    describe "index page", js: true do
      context 'datatable' do
        let(:parent_object1) { FactoryBot.create(:parent_object, oid: 2_034_600, admin_set: AdminSet.find_by_key('brbl')) }
        let(:parent_object2) { FactoryBot.create(:parent_object, oid: 2_005_512, admin_set: AdminSet.find_by_key('brbl')) }

        before do
          stub_metadata_cloud('2034600')
          stub_metadata_cloud('2005512')
          parent_object1
          parent_object2
          visit parent_objects_path
        end

        it 'has multiple Parent Objects' do
          within '#parent-objects-datatable' do
            expect(page).to have_xpath '//*[@id="2034600"]/td[@class="sorting_1"]/a[1]', text: '2034600'
            expect(page).to have_xpath '//*[@id="2005512"]/td[@class="sorting_1"]/a[1]', text: '2005512'
          end
        end
      end

      context "clicking ReIndex button" do
        before do
          visit parent_objects_path
        end

        it "does not Reindex if a reindex job is already in progress" do
          allow(ParentObject).to receive(:cannot_reindex).and_return(:true)
          click_on("Reindex")
          page.driver.browser.switch_to.alert.accept
          expect(page.body).to include 'There is already a Reindex job in progress, please wait for that job to complete before submitting a new reindex request'
        end

        it "does not Reindex without confirmation" do
          expect(ParentObject).not_to receive(:solr_index)
          click_on("Reindex")
          expect(page.driver.browser.switch_to.alert.text).to eq("Are you sure you want to proceed? This action will reindex the entire contents of the system.")
        end

        it "does Reindex with confirmation" do
          expect(ParentObject).to receive(:solr_index).and_return(nil).once
          click_on("Reindex")
          expect(page.driver.browser.switch_to.alert.text).to eq("Are you sure you want to proceed? This action will reindex the entire contents of the system.")
          page.driver.browser.switch_to.alert.accept
        end
      end

      context "clicking Metadata button" do
        before do
          visit parent_objects_path
        end

        it "does not update metadata without confirmation" do
          expect(ParentObject).not_to receive(:order)
          click_on("Update Metadata")
          expect(page.driver.browser.switch_to.alert.text).to eq("Are you sure you want to proceed?  This action will update metadata for the entire contents of the system.")
        end

        it "does update metadata with confirmation" do
          click_on("Update Metadata")
          order = double
          offset = double
          where = double
          allow(offset).to receive(:limit).and_return([])
          allow(order).to receive(:offset).and_return(offset)
          allow(ParentObject).to receive(:where).with({}).and_return(ParentObject.where({}))
          expect(ParentObject).to receive(:where).with('').and_return(where)
          expect(where).to receive(:order).and_return(order)
          expect(page.driver.browser.switch_to.alert.text).to eq("Are you sure you want to proceed?  This action will update metadata for the entire contents of the system.")
          page.driver.browser.switch_to.alert.accept
        end
      end

      context "logged in without sysadmin rights" do
        let(:user) { FactoryBot.create(:user) }

        before do
          login_as user
          visit parent_objects_path
        end

        it "does not update metadata without confirmation" do
          expect(page).to have_button('Update Metadata', disabled: true)
          expect(page).to have_button('Reindex', disabled: true)
        end
      end

      context "logged in without any editor rights" do
        let(:user) { FactoryBot.create(:user) }

        before do
          brbl = AdminSet.find_by_key('brbl')
          sml = AdminSet.find_by_key('sml')
          user.remove_role(:editor, brbl) if brbl
          user.remove_role(:editor, sml) if sml
          login_as user
          visit parent_objects_path
        end

        it "does allow create parent" do
          expect(page).to have_button('New Parent', disabled: true)
        end
      end

      context "logged in with editor rights" do
        let(:user) { FactoryBot.create(:user) }
        let(:admin_set) { FactoryBot.create(:admin_set, key: "adminset") }

        before do
          login_as user
          visit parent_objects_path
        end

        it "does allow create parent" do
          expect(page).to have_button('New Parent', disabled: false)
        end

        it "does not allow editing of oid for non-sysadmin" do
          click_on "New Parent"
          expect(page).to have_selector("#parent_object_oid[readonly]")
        end
      end
    end

    context "when logged in without admin set roles" do
      before do
        user.remove_role(:editor, AdminSet.find_by_key('brbl'))
        visit "parent_objects/new"
        stub_metadata_cloud("10001192")
        fill_in('Oid', with: "10001192")
        select('Beinecke Library')
        select('Ladybird')
      end
      it "does not allow creation of new parent with wrong admin set" do
        click_on("Create Parent object")
        expect(page.body).to include 'Access denied'
      end
    end

    context "when logged in with access to only some admin set roles", js: true do
      let(:user) { FactoryBot.create(:user) }
      let(:admin_set) { FactoryBot.create(:admin_set, key: "adminset") }
      let(:admin_set2) { FactoryBot.create(:admin_set, key: "adminset2", label: "AdminSet2") }
      let(:parent_object1) { FactoryBot.create(:parent_object, oid: "2002826", admin_set_id: admin_set.id) }
      let(:parent_object2) { FactoryBot.create(:parent_object, oid: "2004548", admin_set_id: admin_set.id) }
      let(:parent_object_no_access) { FactoryBot.create(:parent_object, oid: "2004549", admin_set_id: admin_set2.id) }
      let(:child_object1) { FactoryBot.create(:child_object, oid: "456789", parent_object: parent_object1) }
      let(:child_object_no_access) { FactoryBot.create(:child_object, oid: "456790", parent_object: parent_object_no_access) }

      before do
        parent_object1
        parent_object2
        parent_object_no_access
        child_object1
        child_object_no_access
        user.add_role(:editor, admin_set)
        login_as user
      end

      it "does not display parent objects the user does not have access to view" do
        visit parent_objects_path
        expect(page).to have_content("2002826")
        expect(page).to have_content("2004548")
        expect(page).not_to have_content("2004549")
      end

      it "allows viewing of the parent object the user has access to" do
        visit parent_object_path("2002826")
        expect(page).not_to have_content("Access denied")
      end

      it "does not allow viewing of the parent object the user does not has access to" do
        visit parent_object_path("2004549")
        expect(page).to have_content("Access denied")
      end

      it "allows editing of the parent object the user has access to" do
        visit edit_parent_object_path("2002826")
        expect(page).not_to have_content("Access denied")
      end

      it "does not allow viewing of the child object the user does not has access to" do
        visit edit_parent_object_path("2004549")
        expect(page).to have_content("Access denied")
      end

      it "does not allow changing parent_object to admin_set user does not have access to" do
        visit edit_parent_object_path("2002826")
        select 'AdminSet2', from: "parent_object[admin_set]"
        click_on(UPDATE_PARENT_OBJECT_BUTTON)

        expect(page).to have_content "Admin set cannot be assigned to a set the User cannot edit"
      end
    end

    context "parent objects page", js: true do
      before do
        visit parent_objects_path
      end

      it "has column visibility button" do
        expect(page).to have_css(".buttons-colvis")
      end
    end
  end

  context "parent objects page", js: true do
    before do
      visit parent_objects_path
    end

    it "has csv button" do
      expect(page).to have_css(".buttons-csv")
    end

    it "has excel button" do
      expect(page).to have_css(".buttons-excel")
    end

    it "has column visibility button" do
      expect(page).to have_css(".buttons-colvis")
    end
  end
end
