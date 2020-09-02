# frozen_string_literal: true

Rails.application.routes.draw do
  resources :child_objects
  resources :mets_xml_imports

  resources :parent_objects do
    collection do
      post :reindex
    end
    member do
      post :update_metadata
    end
  end

  devise_for :users
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
  get '/delayed_job', to: redirect('/management/users/sign_in')
end
