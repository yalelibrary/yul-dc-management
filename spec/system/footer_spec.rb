# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'footer', type: :system do
  before do
    visit '/'
  end

  it 'has css' do
    expect(page).to have_css '.branch-name'
  end
end
