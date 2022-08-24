# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module Reassociatable
  extend ActiveSupport::Concern

  BLANK_VALUE = "_blank_"

  # triggers the reassociate process
  def reassociate_child_oids
    return unless batch_action == "reassociate child oids"
    parents_needing_update, parent_destination_map = update_child_objects
    update_related_parent_objects(parents_needing_update, parent_destination_map)
  end

  # finds which parents are needed to update
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def update_child_objects
    self.admin_set = ''
    sets = admin_set
    return unless batch_action == "reassociate child oids"
    parents_needing_update = []

    parent_destination_map = {}

    parsed_csv.each_with_index do |row, index|
      co = load_child(index, row["child_oid"].to_i)
      po = load_parent(index, row["parent_oid"].to_i)
      next unless co.present? && po.present?

      sets << ', ' + AdminSet.find(po.authoritative_metadata_source_id).key
      split_sets = sets.split(',').uniq.reject(&:blank?)
      self.admin_set = split_sets.join(', ')
      save

      attach_item(po)
      attach_item(co)

      next unless user_update_child_permission(co, po)

      parents_needing_update << co.parent_object.oid
      parents_needing_update << row["parent_oid"].to_i
      parent_destination_map[co.parent_object.oid] = (parent_destination_map[co.parent_object.oid] || Set.new) << row["parent_oid"].to_i

      reassociate_child(co, po)

      values_to_update = check_headers(child_headers, row)
      update_child_values(values_to_update, co, row, index)
    end
    [parents_needing_update, parent_destination_map]
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  # verifies headers are included. child headers found in csv_exportable:90
  def check_headers(headers, row)
    possible_headers = headers
    values_to_update = []
    possible_headers.each do |h|
      values_to_update << h if row.headers.include?(h)
    end
    values_to_update
  end

  def check_for_blank(value)
    return nil if value == BLANK_VALUE
    value
  end

  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/CyclomaticComplexity
  # updates values based on column values for child object
  def update_child_values(values_to_update, co, row, index)
    values_to_update.each do |h|
      if h == 'viewing_hint'
        co.viewing_hint = valid_view(check_for_blank(row[h]), co.oid)
        # should not update parent title or call number
      elsif values_to_update.include? h
        if h == 'label'
          co.label = check_for_blank(row[h])
        elsif h == 'caption'
          co.caption = check_for_blank(row[h])
        elsif h == 'order'
          order = extract_order(index, row)
          return false if order == :invalid_order # message says skipping row, returning
          co.order = order
        elsif h == 'child_oid' || h == 'parent_oid'
          next
        end
      else
        next
      end
      co.save
    end
  end
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/CyclomaticComplexity

  # assigns the child to the new parent
  def reassociate_child(co, po)
    if po.redirect_to.present?
      failure_event_for_child(co, po.oid)
    else
      co.parent_object = po
      processing_event_for_child(co)
      co.save!
    end
  end

  # alerts user of unsuccessful reassociation event
  def failure_event_for_child(co, po_oid)
    batch_processing_event("Child #{co.oid} cannot be reassociated to redirected parent object: #{po_oid}", 'Skipped Row')
  end

  # alerts user of successful reassociation event
  def processing_event_for_child(co)
    co.current_batch_process = self
    co.current_batch_connection = batch_connections.find_or_create_by(connectable: co)
    co.current_batch_connection.save!
    co.processing_event("Child has parent #{co.parent_object.oid}", 'reassociate-complete')
  end

  # checks the increment is correct and in order
  def extract_order(index, row)
    unless row["order"]&.to_i&.positive? || row["order"] == '0'
      batch_processing_event("Skipping row [#{index + 2}] with invalid order [#{row['order']}] (Parent: #{row['parent_oid']}, Child: #{row['child_oid']})", 'Skipped Row')
      return :invalid_order
    end
    row["order"].to_i
  end

  # finds child object and adds alert if child cannot be found
  def load_child(index, oid)
    co = ChildObject.find_by_oid(oid)
    batch_processing_event("Skipping row [#{index + 2}] with Child Missing #{oid}", 'Skipped Row') unless co
    co
  end

  # finds parent object and adds alert if parent cannot be found
  def load_parent(index, oid)
    po = ParentObject.find_by_oid(oid)
    batch_processing_event("Skipping row [#{index + 2}] with Parent Missing #{oid}", 'Skipped Row') unless po
    po
  end

  # rubocop:disable Metrics/LineLength
  # checks if viewing hint is valid
  def valid_view(viewing_hint, oid)
    if ChildObject.viewing_hints.include? viewing_hint
      viewing_hint
    else
      batch_processing_event("Child #{oid} did not update value for Viewing Hint. Value: #{viewing_hint} is invalid. For field Viewing Hint please use: non-paged, facing-pages, or leave column empty", 'Invalid Vocabulary')
      nil
    end
  end
  # rubocop:enable Metrics/LineLength

  # rubocop:disable Metrics/AbcSize
  # updates count of parent objects and regenerates manifest pdf and reindexes solr.
  def update_related_parent_objects(parents_needing_update, parent_destination_map)
    return unless batch_action == "reassociate child oids" || batch_action == "delete child objects"
    parents_needing_update.uniq.each do |oid|
      po = ParentObject.find(oid)
      update_child_count(po, parent_destination_map)
      # If the child objects have changed, we'll need to re-create the manifest and PDF objects
      # and re-index to Solr
      po.current_batch_process = self
      po.current_batch_connection = batch_connections.find_or_create_by(connectable: po)
      po.current_batch_connection.save!
      po.save!
      if po.should_create_manifest_and_pdf?
        GenerateManifestJob.perform_later(po, self, po.current_batch_connection)
      else
        po.solr_index_job
      end
    end
  end
  # rubocop:enable Metrics/AbcSize

  def update_child_count(po, parent_destination_map)
    po.child_object_count = po.child_objects.count
    return unless po.child_object_count.zero?
    if parent_destination_map[po.oid]&.length == 1
      po.redirect_to = "https://collections.library.yale.edu/catalog/#{parent_destination_map[po.oid].first}"
    else
      batch_processing_event("Unable to redirect parent with 0 children: [Parent #{po.oid} had children moved to #{parent_destination_map[po.oid]}]")
    end
  end
end
# rubocop:enable Metrics/ModuleLength
