# frozen_string_literal: true

Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root to: 'management#index'
  get 'management/index'
  get 'management/', to: 'management#index'

  get "management/index_to_solr/:metadata_source", to: 'management#index_to_solr', as: 'metadata_source'
  get "management/update_database", to: 'management#update_database', as: 'update_database'
  get "management/update_from_activity_stream", to: "management#update_from_activity_stream", as: "update_from_activity_stream"
end
