# frozen_string_literal: true

class Api::ParentObjectsController < ApplicationController
  skip_before_action :authenticate_user!
  
  def retrieve_metadata
    return unless parent_found
    return unless parent_visibility_valid(@parent_object)
    render json: {
      "dcs": {
          "oid": "#{@parent_object.oid}",
          "visibility": "#{@parent_object.visibility}",
          "metadata_source": "#{@parent_object.authoritative_metadata_source_id}",
          "bib":  "#{@parent_object.bib}",
          "holding":  "#{@parent_object.holding}",
          "item":  "#{@parent_object.item}",
          "barcode":  "#{@parent_object.barcode}",
          "aspace_uri":  "#{@parent_object.aspace_uri}",
          "admin_set": "#{@parent_object.admin_set.label}",   
          "child_object_count": "#{@parent_object.child_object_count}",
          "representative_child_oid": "#{@parent_object.representative_child_oid}",
          "rights_statement": "#{@parent_object.rights_statement}",
          "extent_of_digitization": "#{@parent_object.extent_of_digitization}",
          "digitization_note": "#{@parent_object.digitization_note}",
          "call_number": "#{@parent_object.call_number}",
          "container_grouping": "#{@parent_object.container_grouping}",
          "redirect_to": "#{@parent_object.redirect_to}",
          "iiif_manifest": "#{ENV['BLACKLIGHT_BASE_URL']}/manifests/#{@parent_object.oid}"  
      }
    }
  end

  def parent_found
    begin
      @parent_object = ParentObject.find(params['oid'].to_i)
    rescue ActiveRecord::RecordNotFound
      render(json: { "title": "Invalid Parent OID" }, status: 404) && (return false)
    end
    @parent_object
  end

  def parent_visibility_valid(parent_object)
    render(json: { "title": "Parent Object is restricted." }, status: 403) && (return false) unless
    parent_object.visibility == "Public" || parent_object.visibility == "Yale Community Only"
    true
  end

  private

    def parent_object_params
      params.require(:parent_object).permit(:oid)
    end

end
