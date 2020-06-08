# frozen_string_literal: true

Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  get 'management/index'
  get 'management/', to: 'management#index'

  get "management/run_task", to: 'management#run_task', as: 'run_solr_index'
end
