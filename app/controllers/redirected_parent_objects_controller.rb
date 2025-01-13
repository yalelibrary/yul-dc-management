# frozen_string_literal: true

class RedirectedParentObjectsController < ApplicationController
  # Allows FontAwesome icons to render on datatable and show pages
  content_security_policy(only: [:index, :show]) do |policy|
    policy.script_src :self, :unsafe_inline
    policy.script_src_attr  :self, :unsafe_inline
    policy.script_src_elem  :self, :unsafe_inline
    policy.style_src :self, :unsafe_inline
    policy.style_src_elem :self, :unsafe_inline
  end

  # GET /redirected_parent_objects
  # GET /redirected_parent_objects.json
  def index
    respond_to do |format|
      format.html
      format.json { render json: RedirectedParentObjectDatatable.new(params, view_context: view_context, current_ability: current_ability) }
    end
  end
end
