# frozen_string_literal: true

class ManagementController < ApplicationController
  def index
    @oid_import = OidImport.new
  end
end
