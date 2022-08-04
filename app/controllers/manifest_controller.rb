# frozen_string_literal: true

class ManifestController < ApplicationController
  before_action :set_token_user, :set_parent_object

  # GET /parent_objects
  # GET /parent_objects.json
  def index
    raise
    @token_ability ||= Ability.new(@token_user)
    if @token_ability.can? :update, @parent_object
      respond_to do |format|
        format.html
        format.json { render json: @parent_object.iiif_manifest }
      end
    end
  end

  # GET /parent_objects/1
  # GET /parent_objects/1.json
  def show; end

  def set_token_user
    header = request.headers['Authorization']
    header = header.split(' ').last if header
    return unless header
    decoded_token = jwt_decode(header)
    token_user = User.where(id: decoded_token[:user_id]).first
    return unless token_user&.active_for_authentication?
    @token_user = token_user
  end

  def set_parent_object
    @parent_object = ParentObject.find(params[:parent_object_id])
  end
end