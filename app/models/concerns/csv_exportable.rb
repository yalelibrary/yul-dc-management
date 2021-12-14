# frozen_string_literal: true

module CsvExportable
  extend ActiveSupport::Concern

  def parent_headers
    ['oid', 'admin_set', 'authoritative_source', 'child_object_count', 'call_number', 
    'container_grouping', 'bib', 'holding', 'item', 'barcode', 'aspace_uri', 'last_ladybird_update', 
    'last_voyager_update', 'last_aspace_update', 'last_id_update', 'visibility', 
    'extent_of_digitization', 'digitization_note', 'project_identifier']
  end

  # rubocop:disable Metrics/AbcSize
  def parent_output_csv
    return nil unless batch_action == 'export parent oids'

    CSV.generate do |csv|
      csv << parent_headers
      sorted_parent_objects.each do |po|
        next csv << po if po.is_a?(Array)

        row = [po.oid, po.admin_set_key, po.authoritative_json['title']&.first, 
        po.child_object_count, po.call_number, po.container_grouping, po.bib, po.holding, po.item, 
        po.barcode, po.aspace_uri, po.last_ladybird_update, po.last_voyager_update,
        po.last_aspace_update, po.last_id_update, po.visibility, po.extent_of_digitization,
        po.digitization_note, po.project_identifier]
        csv << row
      end
    end
  end

  # rubocop:enable Metrics/AbcSize
  def sorted_parent_objects
    had_events = batch_ingest_events_count.positive?
    arr = []
    oids.each_with_index do |oid, index|
      begin
        po = ParentObject.find(oid.to_i)
        next unless check_can_view(current_ability, index, po, arr, had_events)
        po.each { |po| arr << po }
      rescue ActiveRecord::RecordNotFound
        parent_not_found(index, oid, arr, had_events)
      end
    end

    # sort first by the parent oid, then by the child objects order in the parent grouping
    arr.sort_by { |po| [po.try(:admin_set_key) || po[0], po.try(:oid) || po[2]] }
  end

  def child_headers
    ['parent_oid', 'child_oid', 'order', 'parent_title', 'call_number', 'label', 'caption', 'viewing_hint']
  end

  # rubocop:disable Metrics/AbcSize
  def child_output_csv
    return nil unless batch_action == 'export child oids'

    CSV.generate do |csv|
      csv << child_headers
      sorted_child_objects.each do |co|
        next csv << co if co.is_a?(Array)

        row = [co.parent_object.oid, co.oid, co.order, co.parent_object.authoritative_json['title']&.first, co.parent_object.call_number, co.label, co.caption, co.viewing_hint]
        csv << row
      end
    end
  end

  # rubocop:enable Metrics/AbcSize
  def sorted_child_objects
    had_events = batch_ingest_events_count.positive?
    arr = []
    oids.each_with_index do |oid, index|
      begin
        po = ParentObject.find(oid.to_i)
        next unless check_can_view(current_ability, index, po, arr, had_events)
        po.child_objects.each { |co| arr << co }
      rescue ActiveRecord::RecordNotFound
        parent_not_found(index, oid, arr, had_events)
      end
    end

    # sort first by the parent oid, then by the child objects order in the parent grouping
    arr.sort_by { |co| [co.try(:parent_object_oid) || co[0], co.try(:order) || co[2]] }
  end

  def parent_not_found(index, oid, arr, had_events)
    row = [oid.to_i, nil, 0, 'Parent Not Found in database', '', '']
    batch_processing_event("Skipping row [#{index + 2}] due to parent not found: #{oid}", 'Skipped Row') unless had_events
    arr << row
  end

  def check_can_view(ability, index, parent_object, arr, had_events)
    return true if ability.can?(:read, parent_object)

    row = [parent_object.oid.to_i, nil, 0, 'Access denied for parent object', '', '']
    batch_processing_event("Skipping row [#{index + 2}] due to parent permissions: #{parent_object.oid}", 'Skipped Row') unless had_events
    arr << row
    false
  end
end
