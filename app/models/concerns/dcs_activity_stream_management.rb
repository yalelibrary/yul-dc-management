# frozen_string_literal: true

module DcsActivityStreamManagement
  extend ActiveSupport::Concern

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def dcs_metadata
    {
      "dcs": {
        "oid": oid.to_s,
        "visibility": visibility.to_s,
        "metadata_source": metadata_source_name,
        "bib": bib.to_s,
        "holding": holding.to_s,
        "item": item.to_s,
        "barcode": barcode.to_s,
        "aspace_uri": aspace_uri.to_s,
        "admin_set": admin_set.label.to_s,
        "child_object_count": child_object_count.to_i,
        "representative_child_oid": representative_child_oid.to_i,
        "rights_statement": rights_statement.to_s,
        "extent_of_digitization": extent_of_digitization.to_s,
        "digitization_note": digitization_note.to_s,
        "call_number": call_number.to_s,
        "container_grouping": container_grouping.to_s,
        "redirect_to": redirect_to.to_s,
        "iiif_manifest": "#{ENV['BLACKLIGHT_BASE_URL']}/manifests/#{oid}",
        "children": child_info
      },
      "metadata": authoritative_json
    }
  end
  # rubocop:enable Metrics/LineLength
  # rubocop:enable Metrics/AbcSize

  def mc_activity_stream_check
    md5_metadata_hash = Digest::MD5.hexdigest(dcs_metadata)
    dcs_activity_stream_update = DcsActivityStreamUpdate.find(oid: oid)
    action_type = dcs_activity_stream_update.nil? ? "Create" : "Update"
    return if !dcs_activity_stream_update.nil? && dcs_activity_stream_update.md5_metadata_hash == md5_metadata_hash

    dcs_activity_stream_update = dcs_activity_stream_update.nil? ? dcs_activity_stream_update : DcsActivityStreamUpdate.new
    dcs_activity_stream_update.md5_metadata_hash = md5_metadata_hash
    dcs_activity_stream_update.oid = oid unless dcs_activity_stream_update.nil?
    dcs_activity_stream_update.save! if send_dcs_activity_stream_update(action_type)
  end

  def send_dcs_activity_stream_update(action_type)
    full_response = MetadataSource.new.mc_get "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/streams/activity/dcs/oid/#{oid}/#{action_type}"
    case full_response.status
    when 200
      Rails.logger.info "#{action_type} sent successfully to activity stream oid: #{oid}"
      return true
    else
      Rails.logger.info "Error sending activity stream #{action_type}: #{full_response.status}, oid: #{oid}"
    end
    false
  rescue => e
    Rails.logger.info "Error sending activity stream #{action_type}: #{e}, oid: #{oid}"
    false
  end

  def child_info
    child_objects.map do |co|
      {
        "oid": co.oid,
        "label": co.label,
        "caption": co.caption
      }
    end
  end

  def metadata_source_name
    return "Ladybird" if authoritative_metadata_source_id == 1
    return "Voyager" if authoritative_metadata_source_id == 2
    return "ArchivesSpace" if authoritative_metadata_source_id == 3
    "Metadata Source name not found"
  end
end
