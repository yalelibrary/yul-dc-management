# frozen_string_literal: true

Rails.application.routes.draw do # rubocop:disable Metrics/BlockLength
  resources :batch_processes do
    collection do
      post :import
      post :trigger_mets_scan
    end
    member do
      get :download
      get :download_created
      get '/parent_objects/:oid', to: 'batch_processes#show_parent', as: :show_parent
      get '/parent_objects/:oid/child_objects/:child_oid', to: 'batch_processes#show_child', as: :show_child
    end
  end
  resources :users, only: [:index]
  resources :child_objects

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
  resources :notifications, only: [:index, :destroy] do
    collection do
      delete :resolve_all
    end
  end

  devise_for :users, skip: [:sessions, :registrations, :passwords], controllers: { omniauth_callbacks: "omniauth_callbacks" }
  devise_scope :user do
    delete 'sign_out', to: 'devise/sessions#destroy', as: :destroy_user_session
  end

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root to: 'management#index'

  get 'api/oid/new(/:number)', to: 'oid_minter#generate_oids', as: :new_oid

  authenticated :user do
    mount DelayedJobWeb, at: "/delayed_job"
  end
  # fall back if not authenticated
  get '/delayed_job', to: redirect('/management/users/auth/cas')
end
