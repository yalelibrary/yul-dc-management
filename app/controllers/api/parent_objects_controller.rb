# frozen_string_literal: true

class Api::ParentObjectsController < ApplicationController
  skip_before_action :authenticate_user!
  
  def retrieve_metadata
    # look for parent
    return unless parent_found
    # check visibility
    return unless parent_visibility_valid(parent_object)
    # return metadata
    render json: {
      "dcs": {
          "oid": "123",
          "visibility": "Public",
          "metadata_source": "ils",
          "bib":  ".....",
          "holding":  ".....",
          "item":  ".....",
          "barcode":  ".....",
          "aspace_uri":  ".....",
          "admin_set": "Beinecke",   
          "child_object_count": 43,
          "representative_child_oid": 123,
          "rights_statement": "....",
          "extent_of_digitization": "...",
          "digitization_note": "...",
          "call_number": "...",
          "container_grouping": "...",
          "redirect_to": "....",
          # use blacklight base url env var
          "iiif_manifest": "https://collections-*.library.yale.edu/manifests/123"  
      }
    }
  end



  def parent_found
    begin
      parent_object = ParentObject.find(params['oid'].to_i)
    rescue ActiveRecord::RecordNotFound
      render(json: { "title": "Invalid Parent OID" }, status: 404) && (return false)
    end
    # maybe this should be @parent_object?
    parent_object
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
