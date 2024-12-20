# frozen_string_literal: true

class UsersController < ApplicationController
  load_and_authorize_resource
  before_action :set_user, only: [:edit, :update, :show]

  # Allows FontAwesome icons to render
  content_security_policy(only: :index) do |policy|
    policy.script_src  :self, :unsafe_inline
    policy.script_src_attr  :self, :unsafe_inline
    policy.script_src_elem  :self, :unsafe_inline
    policy.style_src :self, :unsafe_inline
    policy.style_src_elem :self, :unsafe_inline
  end
    
  def index
    respond_to do |format|
      format.html
      format.json { render json: UserDatatable.new(params, view_context: view_context) }
    end
  end

  def edit; end

  def new
    @user = User.new(provider: 'cas')
  end

  def create
    @user = User.new(user_params.merge(provider: 'cas'))

    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, notice: 'User was successfully created.' }
        format.json { render :show, status: :created, location: @admin_set }
      else
        format.html { render :new }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

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

  def show_token
    info = { user_id: current_user&.id }
    render inline: jwt_encode(info)
  end

  def show; end

  private

  def user_params
    params.require(:user).permit(:email, :deactivated, :sysadmin, :first_name, :last_name, :uid)
  end

  def set_user
    @user = User.find(params[:id])
  end
end
