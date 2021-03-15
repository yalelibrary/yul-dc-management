# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "ChildObjects", type: :system, prep_metadata_sources: true, prep_admin_sets: true do
  let(:user) { FactoryBot.create(:user) }
  let(:parent_object) { FactoryBot.create(:parent_object, admin_set: AdminSet.find_by_key("brbl")) }
  before do
    stub_ptiffs_and_manifests
    login_as user
    stub_metadata_cloud("2004628")
  end
  around do |example|
    perform_enqueued_jobs do
      example.run
    end
  end

  it "creates child objects" do
    parent_object
    visit(child_objects_path)
    expect(page).to have_content("1042003")
    expect(page).to have_link("Edit")
    click_on("Edit")
    expect(page).to have_content("Caption")
    expect(page).to have_content("Viewing hint")
    select("non-paged")
    click_on("Update Child object")
    expect(page).to have_content("Child object was successfully updated.")
    expect(page).to have_content("non-paged")
  end

  context "when logged in with access to only some admin set roles", js: true do
    let(:user) { FactoryBot.create(:user) }
    let(:admin_set) { FactoryBot.create(:admin_set, key: "adminset") }
    let(:admin_set2) { FactoryBot.create(:admin_set, key: "adminset2") }
    let(:parent_object1) { FactoryBot.create(:parent_object, oid: "2002826", admin_set_id: admin_set.id) }
    let(:parent_object_no_access) { FactoryBot.create(:parent_object, oid: "2004549", admin_set_id: admin_set2.id) }
    let(:child_object1) { FactoryBot.create(:child_object, oid: "456789", parent_object: parent_object1) }
    let(:child_object_no_access) { FactoryBot.create(:child_object, oid: "456790", parent_object: parent_object_no_access) }

    before do
      parent_object1
      parent_object_no_access
      child_object1
      child_object_no_access
      user.add_role(:viewer, admin_set)
      login_as user
    end

    it "does allow viewing of the child object the user has access to" do
      visit child_object_path(child_object1)
      expect(page).not_to have_content("Access denied")
    end

    it "does not allow viewing of the child object the user has access to" do
      visit child_object_path(child_object_no_access)
      expect(page).to have_content("Access denied")
    end
  end
end
