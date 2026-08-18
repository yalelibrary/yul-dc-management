# frozen_string_literal: true

# Applies IIIF structure (ranges) to parent objects from a CSV, as an alternative to the structure editor.
# rubocop:disable Metrics/ModuleLength
module Structurable
  extend ActiveSupport::Concern

  STRUCTURE_HEADERS = %w[oid child_oid order_in_range range_name range_order].freeze
  ALL_PARENTS = :all_parents

  def update_structure_ranges
    return unless batch_action == "update structure ranges"
    self.admin_set = ''
    sets = admin_set
    return unless structure_headers_present?

    plan, parents, rejected = build_structure_plan(sets)
    reject_structure_parents(plan, parents, rejected)
    applied = apply_structure_plan(plan, parents)
    regenerate_structure_manifests(applied)
  end

  # THE CSV IS UNUSABLE WITHOUT EVERY COLUMN, SO THIS ABORTS THE RUN RATHER THAN SKIPPING EACH ROW
  def structure_headers_present?
    missing = STRUCTURE_HEADERS - (parsed_csv.headers || []).compact.map(&:strip)
    return true if missing.empty?
    batch_processing_event("Process failed. The CSV is missing required column(s): #{missing.join(', ')}", 'error')
    false
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Layout/LineLength
  def build_structure_plan(sets)
    plan = {}
    parents = {}
    rejected = Set.new

    parsed_csv.each_with_index do |row, index|
      oid = row['oid'].to_s.strip
      if oid.blank?
        batch_processing_event("Process failed. Row [#{index + 2}] has a blank oid.", 'error')
        rejected << ALL_PARENTS
        next
      end

      po = structure_parent_for(oid, index, parents, sets)
      if po == false
        rejected << oid
        next
      end

      canvas = structure_row_to_canvas(row, po, index)
      if canvas.nil?
        rejected << oid
        next
      end

      rejected << oid unless add_canvas_to_structure_plan(plan, oid, canvas, index)
    end

    [plan, parents, rejected]
  end

  def reject_structure_parents(plan, parents, rejected)
    oids = rejected.dup
    oids.merge(plan.keys) if oids.delete?(ALL_PARENTS)

    oids.each do |oid|
      plan.delete(oid)
      batch_processing_event("Skipping parent oid: #{oid} because one or more of its rows were invalid. No structure was changed for this parent.", 'Skipped Row')
      po = parents[oid]
      next unless po

      attach_item(po)
      po.processing_event("Structure was not applied because one or more CSV rows were invalid", 'failed')
    end
  end

  def structure_parent_for(oid, index, parents, sets)
    unless parents.key?(oid)
      parents[oid] = updatable_parent_object(oid, index)
      if parents[oid]
        add_admin_set_to_bp(sets, parents[oid])
        save!
      end
    end
    parents[oid]
  end

  def structure_row_to_canvas(row, po, index)
    oid = po.oid
    name = row['range_name'].to_s.strip
    valid = true
    if name.blank?
      batch_processing_event("Skipping row [#{index + 2}] with parent oid: #{oid} because range_name is blank", 'Invalid Blank')
      valid = false
    end
    if row['child_oid'].to_s.strip.blank?
      batch_processing_event("Skipping row [#{index + 2}] with parent oid: #{oid} because child_oid is blank", 'Invalid Blank')
      valid = false
    end

    order_in_range = structure_integer(row['order_in_range'], 'order_in_range', oid, index)
    range_order = structure_integer(row['range_order'], 'range_order', oid, index)
    valid = false if order_in_range == :invalid || range_order == :invalid
    return nil unless valid

    co = structure_child_for(row, po, index)
    return nil if co.nil?

    { child_oid: co.oid, label: co.label, position: order_in_range,
      range_name: name, range_order: range_order, row: index + 2 }
  end

  def structure_integer(value, column, oid, index)
    raw = value.to_s.strip
    unless raw.match?(/\A\d+\z/)
      batch_processing_event("Skipping row [#{index + 2}] with parent oid: #{oid} because #{column} [#{value}] is not a non-negative integer", 'Skipped Row')
      return :invalid
    end
    raw.to_i
  end

  def structure_child_for(row, po, index)
    child_oid = row['child_oid'].to_s.strip
    co = ChildObject.find_by(oid: child_oid)
    if co.blank?
      batch_processing_event("Skipping row [#{index + 2}] with parent oid: #{po.oid} because child oid: #{child_oid} was not found in local database", 'Skipped Row')
      return nil
    end
    unless co.parent_object_oid == po.oid
      batch_processing_event("Skipping row [#{index + 2}] with parent oid: #{po.oid} because child oid: #{child_oid} belongs to parent object: #{co.parent_object_oid}", 'Skipped Row')
      return nil
    end
    co
  end

  def add_canvas_to_structure_plan(plan, oid, canvas, index)
    name = canvas[:range_name]
    bucket = ((plan[oid] ||= {})[name] ||= { range_order: canvas[:range_order], first_row: canvas[:row], canvases: [] })

    if bucket[:range_order] != canvas[:range_order]
      batch_processing_event("Skipping row [#{index + 2}] with parent oid: #{oid} because range [#{name}] has conflicting range_order values [#{bucket[:range_order]}] and [#{canvas[:range_order]}]", 'Skipped Row')
      return false
    end
    if bucket[:canvases].any? { |c| c[:child_oid] == canvas[:child_oid] }
      batch_processing_event("Skipping row [#{index + 2}] with parent oid: #{oid} because child oid: #{canvas[:child_oid]} appears more than once in range [#{name}]", 'Skipped Row')
      return false
    end
    bucket[:canvases] << canvas
    true
  end

  def apply_structure_plan(plan, parents)
    plan.filter_map do |oid, ranges|
      po = parents[oid]
      attach_item(po)
      po.processing_event("Processing has been queued", "processing-queued")
      begin
        build_structure_ranges_for(po, ranges)
        po.processing_event("Structure updated with #{ranges.size} range(s) from CSV", 'update-complete')
        po
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
        batch_processing_event("Skipping parent oid: #{oid} because its structure could not be saved: #{e.message}", 'Skipped Row')
        po.processing_event("Structure could not be saved: #{e.message}", 'failed')
        nil
      end
    end
  end

  def build_structure_ranges_for(po, ranges)
    ActiveRecord::Base.transaction do
      IiifRangeBuilder.new.destroy_existing_structure_by_parent_oid(po.oid, source: Structure::EDITOR)

      # sort_by is not stable, so first_row / row break ties by order of appearance in the CSV
      ranges.sort_by { |_name, r| [r[:range_order], r[:first_row]] }.each_with_index do |(name, r), range_index|
        range = StructureRange.create!(resource_id: SecureRandom.uuid, label: name, position: range_index,
                                       parent_object_oid: po.oid, top_level: true, structure_id: nil,
                                       source: Structure::EDITOR)
        r[:canvases].sort_by { |c| [c[:position], c[:row]] }.each_with_index do |c, canvas_index|
          StructureCanvas.create!(resource_id: IiifRangeBuilder.child_id_to_uri(c[:child_oid], po.oid),
                                  label: c[:label], position: canvas_index, parent_object_oid: po.oid,
                                  child_object_oid: c[:child_oid], structure_id: range.id,
                                  source: Structure::EDITOR)
        end
      end
    end
  end

  def regenerate_structure_manifests(applied)
    applied.uniq(&:oid).each do |po|
      if po.should_create_manifest_and_pdf?
        GenerateManifestJob.perform_later(po, self, po.current_batch_connection)
      else
        po.solr_index_job
      end
    end
  end
end
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/MethodLength
# rubocop:enable Layout/LineLength
