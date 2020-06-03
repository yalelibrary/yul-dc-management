# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "Test sanity check", type: :system do
  it "runs rspec" do
    true
  end

  describe 'index' do
    it 'has a link to run the rake task' do
      visit solr_task_path

      click_on("Index to Solr")
      expect(page.status_code).to eq(200)
      expect(page).to have_content(/Your files have been indexed/)
    end
  end
end
