# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "ChildObjects", type: :system, prep_metadata_sources: true do
  let(:user) { FactoryBot.create(:user) }
  let(:parent_object) { FactoryBot.create(:parent_object) }
  before do
    stub_ptiffs_and_manifests
    login_as user
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
end
