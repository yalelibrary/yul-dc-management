# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'Recurring Jobs', type: :system, prep_metadata_sources: true, prep_admin_sets: true, js: true do
  let(:user) { FactoryBot.create(:sysadmin_user) }
  let(:running_logger) { FactoryBot.create(:running_activity_stream_log, created_at: DateTime.current - 24.hours) }
  let(:running_activity_stream_log_active) { FactoryBot.create(:running_activity_stream_log, run_time: DateTime.current - 8.hours) }

  def queue_adapter_for_test
    ActiveJob::QueueAdapters::DelayedJobAdapter.new
  end

  context 'Reoccuring Job page' do
    before do
      login_as user
      visit reoccurring_jobs_path
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
  end

  context 'Resetting the Logger status' do
    before do
      running_logger
      login_as user
      visit reoccurring_jobs_path
    end

    it 'can see the Manually Reset button and manually reset the status if the Log is older than 12 hours with a Running status' do
      # running_logger.created_at = "2023-07-08 14:59:47.016376000 +0000"
      # running_logger.save
      expect(running_logger.status).to eq("Running")
      click_on "Check status of the Recurring Job"
      expect(page).to have_button('Manually Reset')
      click_on "Manually Reset"
      running_logger.reload
      expect(running_logger.status).to eq("Manually Reset")
    end

    it 'cannot see the Manually Reset button if the Logs is not older than 12 hours with a Running status' do
      running_activity_stream_log_active
      click_on "Check status of the Recurring Job"
      expect(page).not_to have_button('Manually Reset')
    end
  end

  context 'Reoccuring Job page' do
    before do
      login_as user
      user.remove_role(:sysadmin)
      visit reoccurring_jobs_path
    end

    it 'cannot Manually Reset if the user is not a system admin' do
      running_activity_stream_log_active
      click_on "Check status of the Recurring Job"
      expect(page).not_to have_button('Manually Reset')
    end
  end
end