# frozen_string_literal: true

Rails.application.routes.draw do # rubocop:disable Metrics/BlockLength
  resources :batch_processes do
    collection do
      post :import
      post :trigger_mets_scan
      get :download_template
    end
    member do
      get :download
      get :download_created
      get '/parent_objects/:oid', to: 'batch_processes#show_parent', as: :show_parent
      get '/parent_objects/:oid/child_objects/:child_oid', to: 'batch_processes#show_child', as: :show_child
    end
  end
  resources :roles, only: [:create] do
    collection do
      delete :remove
    end
  end

  resources :users, only: [:index, :edit, :update, :show, :new, :create]
  resources :child_objects
  resources :admin_sets
  resources :preservica_ingests

  resources :parent_objects do
    collection do
      post :reindex
      post :all_metadata
    end
    member do
      post :update_metadata
      get :select_thumbnail
      get :solr_document
    end
  end

  devise_for :users, skip: [:sessions, :registrations, :passwords], controllers: { omniauth_callbacks: "omniauth_callbacks" }
  devise_scope :user do
    delete 'sign_out', to: 'devise/sessions#destroy', as: :destroy_user_session
  end

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root to: 'management#index'

  get 'api/oid/new(/:number)', to: 'oid_minter#generate_oids', as: :new_oid

  devise_scope :user do
    authenticated :user, ->(user) { user.sysadmin } do
      mount DelayedJobWeb, at: '/delayed_job'
      get '/delayed_job_dashboard', to: 'delayed_job_dashboard#index', as: 'dashboard'
      get '/delayed_job_dashboard/failed', to: 'delayed_job_dashboard#failed_jobs', as: "failed_jobs"
      get '/delayed_job_dashboard/working', to: 'delayed_job_dashboard#working_jobs', as: "working_jobs"
      get '/delayed_job_dashboard/pending', to: 'delayed_job_dashboard#pending_jobs', as: "pending_jobs"
      get '/delayed_job_dashboard/show/:id', to: 'delayed_job_dashboard#show', as: "show_job"
      post '/delayed_job_dashboard/requeue/:id', to: 'delayed_job_dashboard#requeue', as: "requeue"
      delete '/delayed_job_dashboard/delete/:id', to: 'delayed_job_dashboard#delete_job', as: "delete_job"
    end

    authenticated :user, ->(user) { user.sysadmin } do
      # authenticated user without the sysadmin role
      get '/*delayed_job_dashboard', to: 'application#access_denied'
      get '/*delayed_job', to: 'application#access_denied'
    end
  end

  # fall back if not authenticated
  get '/delayed_job', to: redirect('/users/auth/cas')
  get '/delayed_job_dashboard', to: redirect('/users/auth/cas')
end
