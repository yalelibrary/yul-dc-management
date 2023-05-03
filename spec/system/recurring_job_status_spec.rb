# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'Recurring Jobs', type: :system, prep_metadata_sources: true, prep_admin_sets: true, js: true do
  let(:user) { FactoryBot.create(:sysadmin_user) }
  let(:running_activity_stream_log) { FactoryBot.create(:running_activity_stream_log) }

  def queue_adapter_for_test
    ActiveJob::QueueAdapters::DelayedJobAdapter.new
  end

  # around do |example|
  #   perform_enqueued_jobs do
  #     original_path_ocr = ENV['OCR_DOWNLOAD_BUCKET']
  #     ENV['OCR_DOWNLOAD_BUCKET'] = "yul-dc-ocr-test"
  #     example.run
  #     ENV['OCR_DOWNLOAD_BUCKET'] = original_path_ocr
  #   end
  # end

  context 'Reoccuring Job page' do
    # around do |example|
    #   perform_enqueued_jobs do
    #     example.run
    #   end
    # end
    before do
      running_activity_stream_log
      login_as user
      visit reoccurring_jobs_path
    end

    it 'cannot Manually Reset if the user is not a system admin' do
      expect(page).to have_button('Manually Reset')
    end

    it 'has a button to check the status' do
      expect(page).to have_link('Check status of the Recurring Job')
    end

    it 'clicking check the status button, displays status' do
      click_link('Check status of the Recurring Job')
      expect(page).to have_content('The recurring job is NOT queued')
    end

    it 'clicking queue recurring job, queues the recurring job' do
      click_link('Check status of the Recurring Job')
      click_on('Queue the Recurring Job')
      click_link('Check status of the Recurring Job')
      expect(page).to have_content('A reoccurring job is set to update metadata from Aspace and Voyager at 1:00am EST')
    end

    it 'can trigger job manually' do
      click_on('Trigger Job Manually')
      page.driver.browser.switch_to.alert.accept
      expect(page).to have_content('The manual job has been queued.')
    end

    it 'can Manually Reset as a system admin' do
      click_on "Check status of the Recurring Job"
      expect(page).to have_button('Manually Reset')
    end
  end

  context 'Reoccuring Job page' do
    before do
      login_as user
      user.remove_role(:sysadmin)
      visit reoccurring_jobs_path
    end

    it 'cannot Manually Reset if the user is not a system admin' do
      click_on "Check status of the Recurring Job"
      expect(page).not_to have_button('Manually Reset')
    end
  end
end
