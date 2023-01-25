# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'Admin Sets', type: :system, js: true do
  let(:admin_set) { FactoryBot.create(:admin_set, key: "admin-set-key", label: "admin-set-label", homepage: "http://admin-set-homepage.com") }
  let(:sysadmin_user) { FactoryBot.create(:sysadmin_user, uid: 'johnsmith2530') }
  let(:user) { FactoryBot.create(:user, uid: 'martinsmith2530') }
  let(:metadata_source) { FactoryBot.create(:metadata_source, display_name: "test source") }

  before do
    admin_set
  end

  context "when user has permission to Sets" do
    before do
      login_as sysadmin_user
    end
    it "display admin sets" do
      visit admin_sets_path
      expect(page).to have_content("admin-set-key")
    end

    it 'displays the user roles tables' do
      visit admin_set_path(admin_set)
      expect(page).to have_css('table', text: 'Viewers')
      expect(page).to have_css('table', text: 'Editors')
    end

    it 'validates preservica credentials' do
      visit admin_set_path(admin_set)
      expect(page).to have_content "Preservica credentials not configured for this Admin Set"
    end

    it 'allows roles to be added to users' do
      visit admin_set_path(admin_set)
      within('table', text: 'Editors') do
        expect(page).not_to have_css('td', text: "#{user.last_name}, #{user.first_name} (#{user.uid})")
      end
      fill_in('uid', with: user.uid)
      select('viewer', from: 'role')
      click_on('Save')
      within('table', text: 'Viewers') do
        expect(page).to have_css('td', text: "#{user.last_name}, #{user.first_name} (#{user.uid})")
      end
      within('table', text: 'Editors') do
        expect(page).not_to have_css('td', text: "#{user.last_name}, #{user.first_name} (#{user.uid})")
      end
    end

    it 'allows roles to be removed from users' do
      visit admin_sets_path
      click_link(admin_set.key.to_s)
      fill_in('uid', with: user.uid)
      select('viewer', from: 'role')
      click_on('Save')
      within('table', text: 'Viewers') do
        expect(page).to have_css('td', text: "#{user.last_name}, #{user.first_name} (#{user.uid})")
      end
      click_on('X')
      expect(page).to have_content("User: #{user.uid} removed as viewer")
      within('table', text: 'Viewers') do
        expect(page).not_to have_css('td', text: "#{user.last_name}, #{user.first_name} (#{user.uid})")
      end
    end

    it 'can export parent objects' do
      expect(BatchProcess.count).to eq 0
      visit admin_sets_path
      click_link(admin_set.key.to_s)
      click_on("Export Parent Objects")
      expect(page).to have_content "CSV is being generated. Please visit the Batch Process page to download."
      expect(BatchProcess.count).to eq 1
      expect(BatchProcess.last.created_file_name).to eq "#{admin_set.key}_export_bp_#{BatchProcess.last.id}.csv"
    end

    it 'can update iiif manifests' do
      admin_set.add_editor(sysadmin_user)
      visit admin_sets_path
      click_link(admin_set.key.to_s)
      click_on("Update IIIF Manifests")
      expect(page).to have_content "IIIF Manifests queued for update."
    end

    it 'removes the viewer role from a user when they are given an editor role' do
      visit admin_sets_path
      click_link(admin_set.key.to_s)
      fill_in('uid', with: user.uid)
      select('viewer', from: 'role')
      click_on('Save')
      within('table', text: 'Viewers') do
        expect(page).to have_css('td', text: "#{user.last_name}, #{user.first_name} (#{user.uid})")
      end
      fill_in('uid', with: user.uid)
      select('editor', from: 'role')
      click_on('Save')
      within('table', text: 'Viewers') do
        expect(page).not_to have_css('td', text: "#{user.last_name}, #{user.first_name} (#{user.uid})")
      end
      within('table', text: 'Editors') do
        expect(page).to have_css('td', text: "#{user.last_name}, #{user.first_name} (#{user.uid})")
      end
    end

    it "display admin edit form" do
      visit admin_sets_path
      within "tr#admin_set_#{admin_set.id}" do
        page.find(:css, 'svg.fa-pencil-alt').click
      end
      expect(find_field('Key').value).to eq('admin-set-key')
      expect(find_field('Label').value).to eq('admin-set-label')
      expect(find_field('Homepage').value).to eq('http://admin-set-homepage.com')
    end

    it "allow editing using form" do
      visit edit_admin_set_path(admin_set)
      expect(find_field('Key').value).to eq('admin-set-key')
      expect(find_field('Label').value).to eq('admin-set-label')
      expect(find_field('Homepage').value).to eq('http://admin-set-homepage.com')
      fill_in('Label', with: 'admin-set2-label')
      click_on("Update Admin Set")
      expect(page).to have_content("admin-set2-label")
      expect(page).to have_content("Admin set was successfully updated.")
    end

    it "allow new using form" do
      visit admin_sets_path
      click_on("New Admin Set")
      fill_in('Key', with: 'admin-set3-key')
      fill_in('Label', with: 'admin-set3-label')
      fill_in('Homepage', with: 'http://admin-set3-homepage.com')
      click_on("Create Admin Set")
      expect(page).to have_content("Admin set was successfully created.")
      expect(page).to have_content("admin-set3-key")
      expect(page).to have_content("admin-set3-label")
      expect(page).to have_content("http://admin-set3-homepage.com")
    end

    it "create fails with invalid url" do
      visit admin_sets_path
      click_on("New Admin Set")
      fill_in('Key', with: 'admin-set3-key')
      fill_in('Label', with: 'admin-set3-label')
      fill_in('Homepage', with: 'h99ttp://admin-set3-homepage.com')
      click_on("Create Admin Set")
      expect(page).to have_content("error prohibited this admin_set from being saved:\nHomepage is invalid")
      expect(find_field('Key').value).to eq('admin-set3-key')
      expect(find_field('Label').value).to eq('admin-set3-label')
    end

    it "create does not submit with missing label" do
      visit admin_sets_path
      click_on("New Admin Set")
      fill_in('Key', with: 'admin-set3-key')
      fill_in('Homepage', with: 'http://admin-set3-homepage.com')
      click_on("Create Admin Set")
      expect(page).to have_content("New Admin Set")
      page.evaluate_script("document.activeElement.id") == "admin_set_key"
    end

    it "edit fails with invalid url" do
      visit edit_admin_set_path(admin_set)
      fill_in('Homepage', with: 'h99ttp://admin-set3-homepage.com')
      click_on("Update Admin Set")
      expect(page).to have_content("error prohibited this admin_set from being saved:\nHomepage is invalid")
    end

    it "edit does not submit with missing label" do
      visit edit_admin_set_path(admin_set)
      fill_in('Key', with: '')
      click_on("Update Admin Set")
      expect(page).to have_content("Editing Admin Set")
      page.evaluate_script("document.activeElement.id") == "admin_set_key"
    end

    it "the label appears on the slide bar" do
      visit root_path
      expect(page).to have_link('Sets')
    end

    it 'has update metadata button' do
      visit admin_set_path(admin_set)
      expect(page).to have_css('a', text: 'Batch Update Metadata')
    end

    context 'update metadata dialog' do
      before do
        metadata_source
        visit admin_set_path(admin_set)
        expect(page).to have_css('a', text: 'Batch Update Metadata')
        click_on('Batch Update Metadata')
      end

      it 'autoselects the current admin set' do
        expect(page.find("#admin_set").value).to eq([admin_set.id.to_s])
      end

      it 'requires selection of metadata sources' do
        expect(page).to have_css('input[value="Update Metadata"]')
        click_on('Update Metadata')
        expect(page.driver.browser.switch_to.alert.text).to eq("Are you sure you want to update the metadata for these Admin Sets?")
        page.driver.browser.switch_to.alert.accept
        message = page.find("#metadata_source_ids").native.attribute("validationMessage")
        expect(message).to eq('Please select an item in the list.')
      end

      it 'starts job when dialog is submitted' do
        expect(UpdateAllMetadataJob).to receive(:perform_later).with(0, admin_set_id: ["", admin_set.id.to_s], redirect_to: nil, authoritative_metadata_source_id: ["", metadata_source.id.to_s])
        expect(page).to have_css('input[value="Update Metadata"]')
        page.find("#metadata_source_ids").set [metadata_source.id.to_s]
        click_on('Update Metadata')
        expect(page.driver.browser.switch_to.alert.text).to eq("Are you sure you want to update the metadata for these Admin Sets?")
        page.driver.browser.switch_to.alert.accept
      end
    end
  end

  context "when user does not have permission to Sets" do
    before do
      admin_set
      login_as user
    end
    it "the label does not appear on the slide bar" do
      visit root_path
      expect(page).to have_no_link('Sets')
    end
    it "cannot access admin sets directly" do
      visit admin_sets_path
      expect(page).to have_content("Access denied")
    end
    it 'cannot update iiif manifests' do
      visit admin_sets_path(admin_set)
      expect(page).to have_content("Access denied")
      expect(page).not_to have_content "Update IIIF Manifests"
    end
    it 'cannot update iiif manifests without edit permission' do
      login_as sysadmin_user
      visit admin_sets_path
      click_link(admin_set.key.to_s)
      click_on("Update IIIF Manifests")
      expect(page).to have_content "User does not have permission to update Admin Set."
    end
  end
end
