# frozen_string_literal: true

class RangeController < ApplicationController
  def index
    text 'Range controller'
  end

  def show
    render json: StructureRange.where(resource_id: params[:id]).first.to_iiif
  end

  def create
    rb = IiifRangeBuilder.new
    parent = ParentObject.find(params[:parent_object_id])
    range = rb.parse_range(parent, JSON.parse(request.raw_post), nil)
    range.parent_object = parent
    redirect_to "/range/#{range.resource_id}"
  end

  def update
    rb = IiifRangeBuilder.new
    parent = ParentObject.find(params[:parent_object_id])
    if current_ability.can? :update, parent && parent.visibility != 'Private'
      json = JSON.parse(request.raw_post)
      id = rb.uuid_from_uri(json['id'])
      exists = StructureRange.exists?(resource_id: id)
      range = rb.parse_range(parent, json, nil)
      status_code = exists ? :ok : :created
      render json: range.to_iiif, status: status_code
    else
      respond_to do |format|
        format.html { redirect_to parent_objects_url, notice: 'User does not have permission to update parent object.' }
        format.json { head :no_content }
      end
    end
  end

  def destroy
    rb = IiifRangeBuilder.new
    parent = ParentObject.find(params[:parent_object_id])
    if current_ability.can? :update, parent && parent.visibility != 'Private'
      json = JSON.parse(request.raw_post)
      range = rb.parse_range(parent, json, nil)
      range.destroy
      respond_to do |format|
        format.html { redirect_to parent_object_range_index_url, notice: 'Range was successfully destroyed.' }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { redirect_to parent_objects_url, notice: 'User does not have permission to update parent object.' }
        format.json { head :no_content }
      end
    end
  end
end
