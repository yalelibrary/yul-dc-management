# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'Admin Sets', type: :system, js: true do
  let(:admin_set) { FactoryBot.create(:admin_set, key: "admin-set-key", label: "admin-set-label", homepage: "http://admin-set-homepage.com") }
  let(:user) { FactoryBot.create(:user, uid: 'johnsmith2530') }

  before do
    admin_set
    login_as user
  end

  it "display admin sets" do
    visit admin_sets_path
    expect(page).to have_content("admin-set-key")
  end

  it "display admin edit form" do
    visit admin_sets_path
    click_link("Edit")
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
end
