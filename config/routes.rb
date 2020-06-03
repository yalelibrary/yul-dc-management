# frozen_string_literal: true

Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  get "solr_task/index", to: 'solr_task#index', as: 'solr_task'
  get "solr_task/run_task", to: 'solr_task#run_task', as: 'run_solr_index'
end
