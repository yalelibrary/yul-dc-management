# frozen_string_literal: true

Rails.application.routes.draw do
  resources :metadata_samples
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root to: 'management#index'
  get 'management/index'
  get 'management/', to: 'management#index'

  get "management/index_to_solr/:metadata_source", to: 'management#index_to_solr', as: 'metadata_source'

  resources :oid_imports do
    collection { post :import }
  end
end
