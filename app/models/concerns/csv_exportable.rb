# frozen_string_literal: true

module CsvExportable
  extend ActiveSupport::Concern

  def output_csv
    return nil unless batch_action == "export child oids"
    headers = ["child_oid", "parent_oid", "order", "parent_title", "label", "caption", "viewing_hint"]
    csv_string = CSV.generate do |csv|
      csv << headers
      oids.each do |oid|
        begin
          po = ParentObject.find(oid.to_i)
          po.child_objects.each do |co|
            row = [co.oid, po.oid, co.order, po.authoritative_json["title"]&.first, co.label, co.caption, co.viewing_hint]
            csv << row
          end
        rescue ActiveRecord::RecordNotFound
          row = ["----", oid, "", "Parent Not Found in database", "", ""]
          csv << row
        end
      end
      csv_string
    end
  end
end
