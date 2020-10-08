# frozen_string_literal: true

Rails.application.routes.draw do
  resources :batch_process_events
  resources :batch_processes do
    collection { post :import }
    member do
      get :download
    end
  end
  resources :child_objects
  resources :mets_xml_imports

  resources :parent_objects do
    collection do
      post :reindex
      post :all_metadata
    end
    member do
      post :update_metadata
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

  resources :metadata_samples
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root to: 'management#index'

  resources :oid_imports do
    collection { post :import }
  end

  get 'api/oid/new(/:number)', to: 'oid_minter#generate_oids', as: :new_oid

  authenticated :user do
    mount DelayedJobWeb, at: "/delayed_job"
  end
  # fall back if not authenticated
  get '/delayed_job', to: redirect('/management/users/auth/cas')
end
