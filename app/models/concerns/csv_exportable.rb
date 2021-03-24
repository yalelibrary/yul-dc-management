# frozen_string_literal: true

module CsvExportable
  extend ActiveSupport::Concern

  def headers
    ["child_oid", "parent_oid", "order", "parent_title", "label", "caption", "viewing_hint"]
  end

  def output_csv
    return nil unless batch_action == "export child oids"
    CSV.generate do |csv|
      csv << headers
      sorted_child_objects.each do |co|
        if co.is_a?(Array)
          csv << co
        else
          row = [co.oid, co.parent_object.oid, co.order, co.parent_object.authoritative_json["title"]&.first, co.label, co.caption, co.viewing_hint]
          csv << row
        end
      end
    end
  end

  def sorted_child_objects
    had_events = batch_ingest_events_count.positive?
    arr = []
    oids.each_with_index do |oid, index|
      begin
        po = ParentObject.find(oid.to_i)
        next unless check_can_view(current_ability, index, po, arr, had_events)
        po.child_objects.each do |co|
          arr << co
        end
      rescue ActiveRecord::RecordNotFound
        parent_not_found(index, oid, arr, had_events)
      end
    end

    arr.sort_by { |co| [co.try(:order) || co[2], co.try(:oid) || co[0]] }
  end

  def parent_not_found(index, oid, arr, had_events)
    row = [nil, oid, 0, "Parent Not Found in database", "", ""]
    batch_processing_event("Skipping row [#{index + 2}] due to parent not found: #{oid}", 'Skipped Row') unless had_events
    arr << row
  end

  def check_can_view(ability, index, parent_object, arr, had_events)
    if ability.can?(:read, parent_object)
      true
    else
      row = [nil, parent_object.oid, 0, "Access denied for parent object", "", ""]
      batch_processing_event("Skipping row [#{index + 2}] due to parent permissions: #{parent_object.oid}", 'Skipped Row') unless had_events
      arr << row
      false
    end
  end
end
