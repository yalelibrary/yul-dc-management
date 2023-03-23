# frozen_string_literal: true

class Api::ParentObjectsController < ApplicationController
  skip_before_action :authenticate_user!

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def retrieve_metadata
    return unless parent_found
    return unless parent_visibility_valid(@parent_object)
    render json: {
      "dcs": {
        "oid": @parent_object.oid.to_s,
        "visibility": @parent_object.visibility.to_s,
        "metadata_source": metadata_source(@parent_object),
        "bib": @parent_object.bib.to_s,
        "holding": @parent_object.holding.to_s,
        "item": @parent_object.item.to_s,
        "barcode": @parent_object.barcode.to_s,
        "aspace_uri": @parent_object.aspace_uri.to_s,
        "admin_set": @parent_object.admin_set.label.to_s,
        "child_object_count": @parent_object.child_object_count.to_s,
        "representative_child_oid": @parent_object.representative_child_oid.to_s,
        "rights_statement": @parent_object.rights_statement.to_s,
        "extent_of_digitization": @parent_object.extent_of_digitization.to_s,
        "digitization_note": @parent_object.digitization_note.to_s,
        "call_number": @parent_object.call_number.to_s,
        "container_grouping": @parent_object.container_grouping.to_s,
        "redirect_to": @parent_object.redirect_to.to_s,
        "iiif_manifest": "#{ENV['BLACKLIGHT_BASE_URL']}/manifests/#{@parent_object.oid}"
      },
      "metadata": metadata_json(@parent_object)
    }, status: 200
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize

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

  def metadata_source(parent_object)
    return "Ladybird" if parent_object.authoritative_metadata_source_id == 1
    return "Voyager" if parent_object.authoritative_metadata_source_id == 2
    return "ArchivesSpace" if parent_object.authoritative_metadata_source_id == 3
    "Metadata Source not found"
  end

  def metadata_json(parent_object)
    return parent_object.ladybird_json if parent_object.authoritative_metadata_source_id == 1
    return parent_object.voyager_json if parent_object.authoritative_metadata_source_id == 2
    return parent_object.aspace_json if parent_object.authoritative_metadata_source_id == 3
    "Metadata not found"
  end

  private

    def parent_object_params
      params.require(:parent_object).permit(:oid)
    end
end
