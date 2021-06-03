# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'header and subheader', type: :system, js: true do
  before do
    visit '/'
  end

  context 'the header' do
    it 'has css' do
      expect(page).to have_css '.main_yale_management_banner'
      expect(page).to have_css '.main_yale_management_banner h1'
    end

    it 'has text for Yale branding' do
      expect(page).to have_content("Yale University Library")
    end
  end

  context 'the subheader' do
    it 'has css' do
      expect(page).to have_css '.sub_yale_management_banner'
      expect(page).to have_css '.sub_yale_management_banner h2'
    end

    it 'has text for Yale branding' do
      expect(page).to have_content("Digital Library Management Portal")
    end
  end
end
