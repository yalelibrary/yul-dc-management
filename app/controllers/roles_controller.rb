# frozen_string_literal: true

class RolesController < ApplicationController
  before_action :set_user
  before_action :set_item, only: [:create]

  def create
    if @item && @user.has_role?(params[:role], @item)
      redirect_back(fallback_location: root_path, flash: { alert: "User: #{@user.uid} is already assigned as #{params[:role]}" })
    elsif @item
      # each user only gets one role per item, remove all others first.
      # This removes the role for all users who have that role, not only @user
      # @user.roles.where(resource: @item).destroy_all

      # Current work around, needs refactor
      params[:role] == "viewer" ? @user.remove_role(:editor, @item) : @user.remove_role(:viewer, @item)
      @user.add_role(params[:role], @item)
      redirect_back(fallback_location: root_path, notice: show_notice(@user, params[:role]))
    else
      @user.add_role(params[:role])
      redirect_back(fallback_location: root_path, notice: show_notice(@user, params[:role]))
    end
  end

  # We tried using the standard destroy action but again, passing in the role id destroys the role for all users who are sharing that role, not just the user whose role we want to destroy
  def remove
    @role = Role.find_by(id: params[:role])
    @admin_set = AdminSet.find_by(id: params[:admin_set])

    @user.remove_role(@role.name, @admin_set)
    redirect_back(fallback_location: root_path, notice: "User: #{@user.uid} removed as #{@role.name}")
  end

  private

    def set_user
      @user = User.find_by(uid: params[:uid])
      return true if @user

      redirect_back(fallback_location: root_path, flash: { alert: "User: #{params[:uid]} not found" })
      false
    end

    def set_item
      @item = params[:item_class]&.constantize&.find(params[:item_id]) if params[:item_id]
    end

    def show_notice(user, role)
      user.deactivated ? "User: #{user.uid} added as #{role}, but is deactivated" : "User: #{user.uid} added as #{role}"
    end
end
