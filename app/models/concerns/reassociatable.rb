# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module Reassociatable
  extend ActiveSupport::Concern

  def reassociate_child_oids
    return unless batch_action == "reassociate child oids"
    parents_needing_update = update_child_objects
    update_related_parent_objects(parents_needing_update)
  end

  def update_child_objects
    return unless batch_action == "reassociate child oids"
    parents_needing_update = []
    parsed_csv.each_with_index do |row, index|
      co = load_child(index, row["child_oid"].to_i)
      old_po_oid = co.parent_object_oid
      po = load_parent(index, row["parent_oid"].to_i)
      next unless co.present? && po.present?

      attach_item(po)
      attach_item(co)

      next unless user_update_child_permission(co, po)

      parents_needing_update << co.parent_object.oid
      parents_needing_update << row["parent_oid"].to_i

      reassociate_child(co, po)

      # byebug
      values_to_update = check_headers(child_headers, row)
      update_child_parent_values(values_to_update, co, row, index, old_po_oid)
    end
    parents_needing_update
  end

  def check_headers(headers, row)
    # byebug
    possible_headers = headers
    values_to_update = []
    possible_headers.each do |h|
      values_to_update << h if row.headers.include?(h)
    end
    values_to_update
  end

  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Metrics/MethodLength
  def update_child_parent_values(values_to_update, co, row, index, old_po_oid)
    values_to_update.each do |header|
      # byebug
      if header == 'viewing_hint'
        co.viewing_hint = valid_view(row[header], co.oid)
        # should not update parent title or call number
      elsif values_to_update.include? header
        if header == 'label'
          co.label = row[header]
        elsif header == 'caption'
          co.caption = row[header]
        elsif header == 'order'
          co.order = extract_order(index, row)
        elsif header == 'redirect_to'
          # byebug
          process_redirect(old_po_oid, row[header])
        elsif header == 'child_oid' || header == 'parent_oid'
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

  def reassociate_child(co, po)
    # byebug
    co.parent_object = po
    processing_event_for_child(co)
    co.save!
  end

  def processing_event_for_child(co)
    co.current_batch_process = self
    co.current_batch_connection = batch_connections.find_or_create_by(connectable: co)
    co.current_batch_connection.save!
    co.processing_event("Child has parent #{co.parent_object.oid}", 'reassociate-complete')
  end

  def extract_order(index, row)
    unless row["order"]&.to_i&.positive? || row["order"] == '0'
      batch_processing_event("Skipping row [#{index + 2}] with invalid order [#{row['order']}] (Parent: #{row['parent_oid']}, Child: #{row['child_oid']})", 'Skipped Row')
      return :invalid_order
    end
    row["order"].to_i
  end

  def load_child(index, oid)
    co = ChildObject.find_by_oid(oid)
    batch_processing_event("Skipping row [#{index + 2}] with Child Missing #{oid}", 'Skipped Row') unless co
    co
  end

  def load_parent(index, oid)
    po = ParentObject.find_by_oid(oid)
    batch_processing_event("Skipping row [#{index + 2}] with Parent Missing #{oid}", 'Skipped Row') unless po
    po
  end

  # rubocop:disable Metrics/LineLength
  def valid_view(viewing_hint, oid)
    if ChildObject.viewing_hints.include? viewing_hint
      viewing_hint
    else
      batch_processing_event("Child #{oid} did not update value for Viewing Hint. Value: #{viewing_hint} is invalid. For field Viewing Hint please use: non-paged, facing-pages, or leave column empty", 'Invalid Vocabulary')
      nil
    end
  end
  # rubocop:enable Metrics/LineLength

  def update_related_parent_objects(parents_needing_update)
    # byebug
    return unless batch_action == "reassociate child oids" || batch_action == "delete child objects"
    byebug
    parents_needing_update.uniq.each do |oid|
      po = ParentObject.find(oid)
      po.child_object_count = po.child_objects.count
      # byebug
      # if the parent object no longer has any associated child objects create a redirect
      # if po.child_objects.count.zero? && po.redirect_to.present?
      #   # do something
      #   redirect(po)
      # end
      # If the child objects have changed, we'll need to re-create the manifest and PDF objects
      # and re-index to Solr
      po.current_batch_process = self
      po.current_batch_connection = batch_connections.find_or_create_by(connectable: po)
      po.current_batch_connection.save!
      po.save!
      GenerateManifestJob.perform_later(po, self, po.current_batch_connection)
    end
  end

  def process_redirect(old_po_oid, redirect_to)
    # byebug
    original_po = ParentObject.find_by_oid(old_po_oid)
    if original_po.child_objects.count.zero?
      original_po.redirect_to = redirect_to
      original_po.save!
    else
      batch_processing_event("Parent object: #{original_po_oid} still has child objects.  Parent must have no child objects before it can be redirected.")
    end
  end
end
# rubocop:enable Metrics/ModuleLength
