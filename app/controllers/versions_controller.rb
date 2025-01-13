# frozen_string_literal: true

class VersionsController < ApplicationController
  # Allows FontAwesome icons to render on index
  content_security_policy(only: :index) do |policy|
    policy.script_src :self, :unsafe_inline
    policy.script_src_attr  :self, :unsafe_inline
    policy.script_src_elem  :self, :unsafe_inline
    policy.style_src :self, :unsafe_inline
    policy.style_src_elem :self, :unsafe_inline
  end

  def index
    parent_object = ParentObject.find(params[:parent_object_id])
    batch_connections = parent_object.batch_connections
    versions = parent_object.versions
    if params[:checked] == 'true'
      bc = batch_connections.select { |n| BatchProcess.find(n.batch_process_id).user.present? }
      v = versions.select { |n| n.whodunnit.present? }
      @results = bc + v
    else
      @results = batch_connections + versions
    end
  end
end
