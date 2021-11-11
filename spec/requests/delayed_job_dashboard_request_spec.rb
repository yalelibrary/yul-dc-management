# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Delayed Jobs Dashboard', type: :request do
  let(:authorized_user) { FactoryBot.create(:sysadmin_user) }
  let(:user) { FactoryBot.create(:user) }
  let(:delayed_job) { FactoryBot.create(:job) }

  after do
    Delayed::Job.delete_all
  end

  describe 'with authorized user' do
    before do
      login_as authorized_user
    end

    it 'displays working jobs' do
      get working_jobs_path
      expect(response).to have_http_status(200)
    end

    it 'displays failed jobs' do
      get failed_jobs_url
      expect(response).to have_http_status(200)
    end

    it 'displays pending jobs' do
      get pending_jobs_path
      expect(response).to have_http_status(200)
    end

    it 'displays dashboard' do
      get delayed_job_dashboard_path
      expect(response).to have_http_status(200)
    end

    it 'redirects after delete' do
      delete delete_job_path(delayed_job.id)
      expect(response).to have_http_status(302)
    end

    it 'redirects after requeue' do
      post requeue_path(delayed_job.id)
      expect(response).to have_http_status(302)
    end
  end

  describe 'with unauthorized user' do
    before do
      login_as user
    end

    it 'redirects working jobs' do
      get working_jobs_url
      expect(response).to have_http_status(301)
    end

    it 'redirects failed jobs' do
      get failed_jobs_path
      expect(response).to have_http_status(301)
    end

    it 'redirects pending jobs' do
      get pending_jobs_path
      expect(response).to have_http_status(301)
    end

    it 'redirects attempts to delete' do
      delete delete_job_path(delayed_job.id)
      expect(response).to have_http_status(301)
    end

    it 'redirects attempts to requeue' do
      post requeue_path(delayed_job.id)
      expect(response).to have_http_status(301)
    end
  end

  describe 'not logged in' do
    it 'redirects working jobs' do
      get working_jobs_url
      expect(response).to have_http_status(301)
    end

    it 'redirects failed jobs' do
      get failed_jobs_path
      expect(response).to have_http_status(301)
    end

    it 'redirects pending jobs' do
      get pending_jobs_path
      expect(response).to have_http_status(301)
    end

    it 'redirects attempts to delete' do
      delete delete_job_path(delayed_job.id)
      expect(response).to have_http_status(301)
    end

    it 'redirects attempts to requeue' do
      post requeue_path(delayed_job.id)
      expect(response).to have_http_status(301)
    end
  end
end
