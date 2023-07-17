# frozen_string_literal: true

class RolesController < ApplicationController
  before_action :set_user
  before_action :set_item
  before_action :set_role
  before_action :verify_user

  def create
    if @item && @user.has_role?(@role, @item)
      redirect_back(fallback_location: root_path, flash: { alert: "User: #{@user.uid} is already assigned as #{@role}" })
    elsif @item
      # each user only gets one role per item, remove all others first.
      @user.users_roles.joins(:role).where(roles: { resource: @item }).delete_all

      @user.add_role(@role, @item)
      redirect_back(fallback_location: root_path, notice: show_notice(@user, @role))
    else
      @user.add_role(@role)
      redirect_back(fallback_location: root_path, notice: show_notice(@user, @role))
    end
  end

  def remove
    @user.users_roles.joins(:role).where(roles: { resource: @item }).delete_all
    redirect_back(fallback_location: root_path, notice: "User: #{@user.uid} removed as #{@role}")
  end

  private

  def verify_user
    authorize!(current_ability, :manage, @item) unless current_user.has_role?(:sysadmin) || current_user.has_role?(:administrator, @item)
  end

  def set_user
    @user = User.find_by(uid: params[:uid])
    return true if @user

    redirect_back(fallback_location: root_path, flash: { alert: "User: #{params[:uid]} not found" })
    false
  end

  def set_role
    @role = params[:role]
  end

  def set_item
    @item = params[:item_class]&.constantize&.find(params[:item_id]) if params[:item_id]
  end

  def show_notice(user, role)
    user.deactivated ? "User: #{user.uid} added as #{role}, but is deactivated" : "User: #{user.uid} added as #{role}"
  end
end
