# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'slidebar', type: :system, js: true do
  before do
    visit '/'
  end

  it 'has css' do
    expect(page).to have_css '.list-group-item'
    expect(page).to have_css '.list-group-item-action'
  end

  it 'has a list of choices when the user is not authenticated' do
    expect(page).to have_content("Dashboard")
    expect(page).to have_content("Parent Objects")
    expect(page).to have_content("Child Objects")
    expect(page).to have_content("Batch Process")
    expect(page).to have_content("Preservation")
    expect(page).to have_content("Notifications")
  end
end
