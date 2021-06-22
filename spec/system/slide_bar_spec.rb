# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'the management application has sidebar', type: :system, js: true do
  before do
    visit '/'
  end

  it 'has css' do
    expect(page).to have_css '.list-group-item'
    expect(page).to have_css '.list-group-item-action'
    expect(page).to have_css '.top-menu-item'
    expect(page).to have_css '.flex-column'
    expect(page).to have_css '.list-group'
    expect(page).to have_css '.sidebar_yale'
    expect(page).to have_css '.border-right'
    expect(page).to have_css '.sign-button'
  end

  it 'has a list of choices when the user is not authenticated' do
    expect(page).to have_content("DASHBOARD")
    expect(page).to have_content("PARENT OBJECTS")
    expect(page).to have_content("CHILD OBJECTS")
    expect(page).to have_content("BATCH PROCESS")
    expect(page).to have_content("PRESERVATION")
  end

  it "item with hovering is visible to the user" do
    find('.sidebar_yale').hover
  end
end
