# frozen_string_literal: true

class ManagementController < ApplicationController
  skip_before_action :authenticate_user!

  # Allows FontAwesome icons to render in header
  content_security_policy(only: [:index, :show]) do |policy|
    policy.script_src :self, :unsafe_inline
    policy.script_src_attr  :self, :unsafe_inline
    policy.script_src_elem  :self, :unsafe_inline
    policy.style_src :self, :unsafe_inline
    policy.style_src_elem :self, :unsafe_inline
  end

  def index
    @batch_process = BatchProcess.new
  end
end
