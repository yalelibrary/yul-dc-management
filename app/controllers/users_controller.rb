# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :set_user, only: [:edit, :update, :show]

  def index
    respond_to do |format|
      format.html
      format.json { render json: UserDatatable.new(params, view_context: view_context) }
    end
  end

  def edit; end

  def update
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to @user, notice: 'User was successfully updated.' }
        format.json { render :show, status: :ok }
      else
        format.html { render :edit }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def show; end

  private

    def user_params
      params.require(:user).permit(:email, :deactivated, :sysadmin, :first_name, :last_name)
    end

    def set_user
      @user = User.find(params[:id])
    end
end
