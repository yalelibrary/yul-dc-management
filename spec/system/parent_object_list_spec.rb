# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "ParentObjects", type: :system, prep_metadata_sources: true, prep_admin_sets: true do
  context "parent objects datatable page", js: true do
    let(:user) { FactoryBot.create(:user) }
    let(:admin_set) { FactoryBot.create(:admin_set, key: "adminset") }
    let(:parent_object1) { FactoryBot.create(:parent_object, oid: "2002826", admin_set_id: admin_set.id) }
    let(:parent_object2) { FactoryBot.create(:parent_object, oid: "2004548", admin_set_id: admin_set.id) }

    before do
      parent_object1
      parent_object2
      user.add_role(:editor, admin_set)
      login_as user
    end

    it "displays parent objects without filter" do
      visit parent_objects_path
      expect(page).to have_content("2002826")
      expect(page).to have_content("2004548")
    end

    it "filters when filter box is filled" do
      visit parent_objects_path
      find("input[placeholder='OID']").set("2002")
      expect(page).to have_content("2002826")
      expect(page).not_to have_content("2004548")
    end

    it "retains filters and fills filter boxes on refresh" do
      visit parent_objects_path
      find("input[placeholder='OID']").set("2002")
      expect(page).to have_content("2002826")
      expect(page).not_to have_content("2004548")
      visit current_path
      expect(page).to have_content("2002826")
      expect(page).not_to have_content("2004548")
      expect(find("input[placeholder='OID']").value).to eq("2002")
    end

    it "clears filter when Clear Filters is clicked" do
      visit parent_objects_path
      find("input[placeholder='OID']").set("2002")
      expect(page).to have_content("2002826")
      expect(page).not_to have_content("2004548")
      click_on("Clear Filters")
      expect(page).to have_content("2002826")
      expect(page).to have_content("2004548")
    end
  end
end
