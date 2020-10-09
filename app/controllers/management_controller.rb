# frozen_string_literal: true

class ManagementController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    @batch_process = BatchProcess.new
  end
end
