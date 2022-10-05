class PermissionSetsController < ApplicationController
  load_and_authorize_resource
  before_action :set_permission_set, only: [:show, :edit, :update, :destroy]

  # GET /permission_sets
  # GET /permission_sets.json
  def index
    authorize!(:view_list, PermissionSet)

    permission_sets = PermissionSet.all
    @visible_permission_sets = permission_sets.order('label ASC').select do |sets|
      User.with_role(:approver, sets).include?(current_user) ||
      User.with_role(:administrator, sets).include?(current_user) || 
      User.with_role(:sysadmin, sets).include?(current_user)
    end

  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_permission_set
      @permission_set = PermissionSet.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def permission_set_params
      params.require(:permission_set).permit(:key, :label)
    end
end
