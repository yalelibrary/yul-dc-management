# frozen_string_literal: true

class RolesController < ApplicationController
  before_action :set_user
  before_action :set_item

  def create
    if @item && @user.has_role?(params[:role], @item)
      redirect_back(fallback_location: root_path, flash: { alert: "User: #{@user.uid} is already assigned as #{params[:role]}" })
    elsif @item
      # each user only gets one role per item, remove all others first.
      @user.roles.where(resource: @item).destroy_all
      @user.add_role(params[:role], @item)
      redirect_back(fallback_location: root_path, notice: "User: #{@user.uid} added as #{params[:role]}")
    else
      @user.add_role(params[:role])
      redirect_back(fallback_location: root_path, notice: "User: #{@user.uid} added as #{params[:role]}")
    end
  end

  def set_user
    @user = User.find_by(uid: params[:uid])
    return true if @user

    redirect_back(fallback_location: root_path, flash: { alert: "User: #{params[:uid]} not found" })
    false
  end

  def set_item
    @item = params[:item_class]&.constantize&.find(params[:item_id]) if params[:item_id]
  end
end
