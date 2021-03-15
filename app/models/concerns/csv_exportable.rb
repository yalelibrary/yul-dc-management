# frozen_string_literal: true

module CsvExportable
  extend ActiveSupport::Concern

  def output_csv
    ability = Ability.new(user)
    return nil unless batch_action == "export child oids"
    headers = ["child_oid", "parent_oid", "order", "parent_title", "label", "caption", "viewing_hint"]
    CSV.generate do |csv|
      csv << headers
      oids.each_with_index do |oid, index|
        begin
          po = ParentObject.find(oid.to_i)
          next unless check_can_view(ability, index, po, csv)
          po.child_objects.each do |co|
            row = [co.oid, po.oid, co.order, po.authoritative_json["title"]&.first, co.label, co.caption, co.viewing_hint]
            csv << row
          end
        rescue ActiveRecord::RecordNotFound
          parent_not_found(index, oid, csv)
        end
      end
    end
  end

  def parent_not_found(index, oid, csv)
    row = ["----", oid, "", "Parent Not Found in database", "", ""]
    batch_processing_event("Skipping row [#{index}] due to parent not found: #{oid}", 'Skipped Row')
    csv << row
  end

  def check_can_view(ability, index, parent_object, csv)
    if ability.can?(:read, parent_object)
      true
    else
      row = ["----", parent_object.oid, "", "Access denied for parent object", "", ""]
      batch_processing_event("Skipping row [#{index}] due to parent permissions: #{parent_object.oid}", 'Skipped Row')
      csv << row
      false
    end
  end
end
