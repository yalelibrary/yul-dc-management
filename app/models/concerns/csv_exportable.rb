# frozen_string_literal: true

module CsvExportable
  extend ActiveSupport::Concern

  def headers
    ["child_oid", "parent_oid", "order", "parent_title", "label", "caption", "viewing_hint"]
  end

  def output_csv
    had_events = batch_ingest_events_count.positive?
    return nil unless batch_action == "export child oids"
    CSV.generate do |csv|
      csv << headers
      oids.each_with_index do |oid, index|
        begin
          po = ParentObject.find(oid.to_i)
          next unless check_can_view(current_ability, index, po, csv, had_events)
          po.child_objects.each do |co|
            row = [co.oid, po.oid, co.order, po.authoritative_json["title"]&.first, co.label, co.caption, co.viewing_hint]
            csv << row
          end
        rescue ActiveRecord::RecordNotFound
          parent_not_found(index, oid, csv, had_events)
        end
      end
    end
  end

  def parent_not_found(index, oid, csv, had_events)
    row = ["----", oid, "", "Parent Not Found in database", "", ""]
    batch_processing_event("Skipping row [#{index}] due to parent not found: #{oid}", 'Skipped Row') unless had_events
    csv << row
  end

  def check_can_view(ability, index, parent_object, csv, had_events)
    if ability.can?(:read, parent_object)
      true
    else
      row = ["----", parent_object.oid, "", "Access denied for parent object", "", ""]
      batch_processing_event("Skipping row [#{index}] due to parent permissions: #{parent_object.oid}", 'Skipped Row') unless had_events
      csv << row
      false
    end
  end
end
