# frozen_string_literal: true

Rails.application.routes.draw do # rubocop:disable Metrics/BlockLength
  resources :batch_processes do
    collection do
      post :export_parent_objects
      post :import
      post :trigger_mets_scan
      get :download_template
    end
    member do
      get :download
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
  resources :permission_sets do
    get 'permission_set_terms', on: :member
    get 'new_term', on: :member
    post 'post_permission_set_terms', on: :member
    post 'deactivate_permission_set_terms', on: :member
    get 'permission_set_terms/:id', to: 'permission_sets#show_term', on: :member
  end
  resources :permission_requests
  resources :preservica_ingests
  resources :redirected_parent_objects
  resources :problem_reports, only: [:index, :create]

  resources :parent_objects do
    collection do
      post :reindex
      post :all_metadata
      post :update_manifests
    end
    member do
      post :update_metadata
      post :sync_from_preservica
      get :select_thumbnail
      get :solr_document
      get :manifest, controller: "manifest"
      post :manifest, to: "manifest#save"
    end
    resources :versions, only: [:index]
    resources :range
  end

  devise_for :users, skip: [:sessions, :registrations, :passwords], controllers: { omniauth_callbacks: "omniauth_callbacks" }
  devise_scope :user do
    delete 'sign_out', to: 'devise/sessions#destroy', as: :destroy_user_session
  end

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root to: 'management#index'

  get 'api/oid/new(/:number)', to: 'oid_minter#generate_oids', as: :new_oid

  get 'api/parent/:oid', to: 'api/parent_objects#retrieve_metadata'

  get 'api/permission_sets/:id/terms', to: 'api/permission_sets#terms_api', as: :terms_api

  get 'api/permission_sets/:sub', to: 'api/permission_sets#retrieve_permissions_data', as: :retrieve_permissions_data

  get 'api/permission_sets/:permission_set_id/permission_set_terms/:permission_set_terms_id/agree/:sub', to: 'api/permission_sets#agreement_term', as: :agreement_term

  namespace :api do
    resources :permission_requests, only: [:create]
  end

  get '/api/download/stage/child/:oid', to: 'download_original#stage'

  get '/show_token', to: 'users#show_token', as: :show_token
  get '/update_token', to: 'manifest#update_token', as: :update_token

  devise_scope :user do
    authenticated :user, ->(user) { user.sysadmin } do
      mount GoodJob::Engine => 'jobs'
    end

    authenticated :user, ->(user) { user.sysadmin } do
      # authenticated user without the sysadmin role
      get '/*jobs', to: 'application#access_denied'
    end
  end

  # fall back if not authenticated
  get '/jobs', to: redirect('users/auth/cas')
end
