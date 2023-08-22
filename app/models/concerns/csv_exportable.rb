# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module CsvExportable
  extend ActiveSupport::Concern

  ########################
  # Parent Object Export
  ########################
  def parent_headers
    ['oid', 'admin_set', 'authoritative_source', 'child_object_count', 'call_number',
     'container_grouping', 'bib', 'holding', 'item', 'barcode', 'aspace_uri',
     'digital_object_source', 'preservica_uri', 'last_ladybird_update',
     'last_voyager_update', 'last_aspace_update', 'last_id_update', 'visibility',
     'extent_of_digitization', 'digitization_note', 'digitization_funding_source', 'project_identifier', 'full_text']
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def parent_output_csv(*admin_set_id)
    return nil unless batch_action == 'export all parent objects by admin set'
    output_csv = CSV.generate do |csv|
      csv << parent_headers
      with_each_parent_object(*admin_set_id) do |po|
        case po
        when ParentObject
          csv << [po.oid, po.admin_set.key, po.source_name,
                  po.child_object_count, po.call_number, po.container_grouping, po.bib, po.holding, po.item,
                  po.barcode, po.aspace_uri, po.digital_object_source, po.preservica_uri,
                  po.last_ladybird_update, po.last_voyager_update,
                  po.last_aspace_update, po.last_id_update, po.visibility, po.extent_of_digitization,
                  po.digitization_note, po.digitization_funding_source, po.project_identifier, extent_of_full_text(po)]
        else
          csv << [po[:id], po[:row2], '-', po[:csv_message], '', '']
          batch_processing_event(po[:batch_message], 'Skipped Row') unless batch_ingest_events_count.positive?
        end
      end
    end
    save_to_s3(output_csv, self)
    output_csv
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  def extent_of_full_text(parent_object)
    children_with_ft = false
    children_without_ft = false

    parent_object.child_objects.each do |object|
      if object.full_text
        children_with_ft = true
      else
        children_without_ft = true
      end

      break if children_with_ft && children_without_ft
    end

    return "Partial" if children_with_ft && children_without_ft # if some children have full text and others dont
    return "None" unless children_with_ft # if none of children have full_text
    "Yes"
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Lint/UselessAssignment
  def with_each_parent_object(*admin_set_id)
    arr = []
    if csv.present?
      imported_csv = CSV.parse(csv, headers: true).presence
      imported_csv.each_with_index do |row, index|
        begin
          admin_set = AdminSet.find_by!(key: row[0])
          self.admin_set = admin_set.key
          save!
          if user.viewer(admin_set) || user.editor(admin_set)
            ParentObject.where(admin_set_id: admin_set.id).order(:oid).find_each do |parent|
              # gives most reuse of find_each
              yield parent
            end
          else
            yield({ row2: admin_set.key, csv_message: 'Access denied for admin set', batch_message: "Skipping row [#{index + 2}] due to  admin set permissions: #{admin_set.key}" })
          end
        rescue ActiveRecord::RecordNotFound
          yield({ row2: row[0], csv_message: 'Admin Set not found in database', batch_message: "Skipping row [#{index + 2}]  due to Admin Set not found: #{row[0]}" })
        end
      end
    else
      admin_set_id.each do |id|
        admin_set = AdminSet.find_by!(id: id.to_i)
        self.admin_set = admin_set.key
        save!
        if user.viewer(admin_set) || user.editor(admin_set)
          ParentObject.where(admin_set_id: id.to_i).order(:oid).find_each do |parent|
            yield parent
          end
        else
          yield({ row2: admin_set.key, csv_message: 'Access denied for admin set', batch_message: "Skipping admin set due to admin set permissions: #{admin_set.key}" })
        end
      end
    end
    arr
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Lint/UselessAssignment

  ########################
  # Parent Metadata Export
  ########################

  # rubocop:disable Metrics/LineLength
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def export_parent_metadata
    return nil unless batch_action == 'export parent metadata'
    csv_rows = []
    self.admin_set = ''
    sets = admin_set
    parent_objects_export_array.each do |po|
      sets << ', ' + po.admin_set.key
      split_sets = sets.split(',').uniq.reject(&:blank?)
      self.admin_set = split_sets.join(', ')
      save!
      row = [po.oid, po.admin_set.key, po.source_name,
             po.child_object_count, po.call_number, po.container_grouping, po.bib, po.holding, po.item,
             po.barcode, po.aspace_uri, po.digital_object_source, po.preservica_uri,
             po.last_ladybird_update, po.last_voyager_update,
             po.last_aspace_update, po.last_id_update, po.visibility, po.extent_of_digitization,
             po.digitization_note, po.digitization_funding_source, po.project_identifier, extent_of_full_text(po)]
      csv_rows << row
    end
    add_error_rows(csv_rows)
    csv_rows.sort_by! { |row| [row[0].to_i, row[2].to_i] }
    output_csv = CSV.generate do |csv|
      csv << parent_headers
      csv_rows.each { |row| csv << row }
    end
    save_to_s3(output_csv, self)
    output_csv
  end
  # rubocop:enable Metrics/LineLength
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  def parent_objects_export_array
    arr = []
    oids.each_with_index do |oid, index|
      begin
        po = ParentObject.find(oid.to_i)
        if current_ability.can?(:read, po)
          arr << po
        else
          (@error_rows ||= []) << { id: oid, csv_message: 'Access denied for parent object', batch_message: "Skipping row [#{index + 2}] due to parent permissions: #{oid}" }
        end
      rescue ActiveRecord::RecordNotFound
        (@error_rows ||= []) << { id: oid, csv_message: 'Parent Not Found in database', batch_message: "Skipping row [#{index + 2}] due to parent not found: #{oid}" }
      end
    end
    arr
  end

  ########################
  # Child Object Export
  ########################

  def child_headers
    ['parent_oid', 'child_oid', 'order', 'parent_title', 'call_number', 'label', 'caption', 'viewing_hint', 'full_text']
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def child_output_csv
    return nil unless batch_action == 'export child oids'
    csv_rows = []
    parent_title_hash = {}
    self.admin_set = ''
    sets = admin_set
    child_objects_array.each do |co|
      parent_title = lookup_parent_title(co, parent_title_hash)
      sets << ', ' + co.parent_object.admin_set.key
      split_sets = sets.split(',').uniq.reject(&:blank?)
      self.admin_set = split_sets.join(', ')
      save!
      row = [co.parent_object.oid, co.oid, co.order, parent_title.presence, co.parent_object.call_number, co.label, co.caption, co.viewing_hint, full_text_status(co)]
      csv_rows << row
    end
    add_error_rows(csv_rows)
    csv_rows.sort_by! { |row| [row[0].to_i, row[2].to_i] }
    output_csv = CSV.generate do |csv|
      csv << child_headers
      csv_rows.each { |row| csv << row }
    end
    save_to_s3(output_csv, self)
    output_csv
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  def full_text_status(child_object)
    child_object.full_text == true ? "Yes" : "No"
  end

  def lookup_parent_title(co, parent_title_hash)
    parent_title_hash[co.parent_object.oid] ||= co.parent_object.authoritative_json&.[]('title')&.first
  end

  def remote_csv_path
    @remote_csv_path ||= "batch/job/#{id}/#{created_file_name}"
  end

  def child_objects_array
    arr = []
    oids.each_with_index do |oid, index|
      begin
        po = ParentObject.find(oid.to_i)
        if current_ability.can?(:read, po)
          po.child_objects.each { |co| arr << co }
        else
          (@error_rows ||= []) << { id: oid, csv_message: 'Access denied for parent object', batch_message: "Skipping row [#{index + 2}] due to parent permissions: #{oid}" }
        end
      rescue ActiveRecord::RecordNotFound
        (@error_rows ||= []) << { id: oid, csv_message: 'Parent Not Found in database', batch_message: "Skipping row [#{index + 2}] due to parent not found: #{oid}" }
      end
    end
    arr
  end

  ########################
  # common
  ########################

  def add_error_rows(csv_rows)
    # only add errors on first run of job
    had_events = batch_ingest_events_count.positive?
    @error_rows&.each do |error_row|
      csv_rows << [error_row[:id], error_row[:row2], '-', error_row[:csv_message], '', '']
      batch_processing_event(error_row[:batch_message], 'Skipped Row') unless had_events
    end
  end

  def save_to_s3(csv, batch_process)
    # generate csv export and save it to s3, save will return s3 response if successful, or raise error
    batch_processing_event("CSV saved to S3", "csv-saved") if CsvExport.new(csv, batch_process).save
  rescue => e
    batch_processing_event("CSV generation failed due to #{e.message}", "failed")
    # do not re-raise Error so job only runs once and fails if CSV can not be saved to S3
    # raise # this reraises the error after we document it
  end
end
# rubocop:enable Metrics/ModuleLength
