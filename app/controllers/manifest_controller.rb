# frozen_string_literal: true

class ManifestController < ApplicationController
  skip_before_action :authenticate_user!, :verify_authenticity_token
  before_action :set_token_user, :set_parent_object

  def manifest
    @token_ability ||= Ability.new(@token_user)
    if @token_ability.can? :update, @parent_object
      respond_to do |format|
        format.html { render json: @parent_object.iiif_manifest }
        format.json { render json: @parent_object.iiif_manifest }
      end
    else
      render json: { "message": "Access denied" }, status: :unauthorized
    end
  end

  def save
    @token_ability ||= Ability.new(@token_user)
    if @token_ability.can? :update, @parent_object
      manifest = JSON.parse(request.raw_post)
      builder = IiifRangeBuilder.new
      builder.destroy_existing_structure_by_parent_oid(@parent_object.oid)
      IiifRangeBuilder.new.parse_structures manifest if manifest["structures"].present?
      GenerateManifestJob.perform_later(@parent_object, nil, current_batch_connection: nil)
      respond_to do |format|
        format.html { render json: @parent_object.iiif_manifest }
        format.json { render json: @parent_object.iiif_manifest }
      end
    else
      render json: { "message": "Access denied" }, status: :unauthorized
    end
  end

  def update_token
    return unless @token_user&.active_for_authentication?
    info = { user_id: @token_user&.id }
    response = {
      token: jwt_encode(info)
    }
    render json: response, status: :ok
  end

  def set_token_user
    header = request.headers['Authorization']
    header = header.split(' ').last if header
    if header
      decoded_token = jwt_decode(header)
      token_user = User.where(id: decoded_token[:user_id]).first
      return unless token_user&.active_for_authentication?
      @token_user = token_user
    else
      @token_user = current_user
    end
  end

  def set_parent_object
    @parent_object = (params[:parent_object_id] || params[:id]) && ParentObject.find(params[:parent_object_id] || params[:id])
  end
end
