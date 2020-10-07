# frozen_string_literal: true

class ManagementController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    @batch_process = BatchProcess.new
    @oid_import = OidImport.new
  end
end
