# frozen_string_literal: true

class IiifRangeBuilder
  # IiifPresentationV3#manifest_base_url delegates here; if the two disagree UV cannot resolve a
  # Range to its Canvases and the range renders but will not navigate.
  DEFAULT_BASE_URL = 'http://localhost/manifests'

  def self.manifest_base_url
    (ENV['IIIF_MANIFESTS_BASE_URL'].presence || DEFAULT_BASE_URL).sub(%r{/+\z}, '')
  end

  def parse_structures(manifest)
    raise 'Not a Manifest' unless manifest['type'] == 'Manifest'
    raise 'No structures property' unless manifest['structures'] && !manifest['structures'].empty?

    results = []
    manifest_uri = manifest['id']
    parent = parent_object_from_uri(manifest_uri)
    ActiveRecord::Base.transaction do
      structures = manifest['structures']
      structures.each_with_index do |structure, index|
        top_level_range = parse_range(parent, structure, index)
        top_level_range.top_level = true
        top_level_range.structure_id = nil
        top_level_range.save!
        results.push top_level_range
      end
    end
    results
  end

  def parse_range(parent, range, position)
    raise 'Not a Range' unless range['type'] == 'Range'

    id = uuid_from_uri(range['id'])
    label = range&.[]('label')&.[]('en')&.[](0) || range['label'].to_s
    result = reuse_preservica_range(parent.oid, id, position, label) ||
             create_editor_range(parent, id, label, position)
    parse_range_items(parent, range, result)
    result
  end

  def create_editor_range(parent, id, label, position)
    destroy_existing_structure(id, parent.oid)
    StructureRange.create!(resource_id: id, label: label, position: position,
                           parent_object_oid: parent.oid, source: Structure::EDITOR)
  end

  # Canvases are rebuilt from the post so an add, a removal or a reorder all take effect. They
  # inherit the range's source: inside a Preservica range they must stay Preservica owned, or the
  # next rebuild would orphan them to the top of the tree instead of clearing them.
  def parse_range_items(parent, range, result)
    result.structures.where(type: 'StructureCanvas').destroy_all
    (range['items'] || []).each_with_index do |item, index|
      raise 'Unexpected type for item in Range' unless %w[Range Canvas].include?(item['type'])

      result.structures << if item['type'] == 'Range'
                             parse_range(parent, item, index)
                           else
                             parse_canvas(parent, item, index, result.source)
                           end
    end
    result.save!
  end

  def parse_canvas(parent, item, position, source = Structure::EDITOR)
    child_id = child_id_from_uri(item['id'], parent.id)
    child = ChildObject.find(child_id)
    StructureCanvas.create!(resource_id: item['id'], label: child.label, position: position,
                            parent_object_oid: parent.oid, child_object_oid: child.oid, source: source)
  end

  # An edit to a Preservica range sticks until the next resync, which reasserts Preservica's own
  # label. The row stays Preservica owned so that rebuild still claims it.
  def reuse_preservica_range(parent_oid, resource_id, position, label)
    range = StructureRange.preservica_built.find_by(parent_object_oid: parent_oid, resource_id: resource_id)
    range&.update!(position: position, label: label)
    range
  end

  # A bare uuid, or a "<base>/range/<uuid>" uri from an older manifest.
  def uuid_from_uri(uri)
    uri.split('/').last
  end

  def parent_object_from_uri(uri)
    parent_oid = parent_oid_from_uri(uri)
    ParentObject.find(parent_oid)
  end

  # Manifest ids come as "<base>/<oid>" or, in older manifests, "<base>/oid/<oid>".
  def parent_oid_from_uri(uri)
    uri.split('/').last
  end

  def self.parent_uri_from_id(id)
    File.join(manifest_base_url, id.to_s)
  end

  def self.uuid_to_uri(uuid)
    File.join(manifest_base_url, 'range', uuid.to_s)
  end

  def child_id_from_uri(uri, parent_oid)
    uri.sub(/.*oid\/#{parent_oid}\/canvas\//, '')
  end

  def self.child_id_to_uri(child_oid, parent_oid)
    File.join(manifest_base_url, "oid/#{parent_oid}/canvas/#{child_oid}")
  end

  def destroy_existing_structure(resource_id, parent_oid)
    Structure.editor_built.where(resource_id: resource_id, parent_object_oid: parent_oid).destroy_all
  end

  def destroy_existing_structure_by_parent_oid(parent_oid, source:)
    remove_structures(parent_oid, Structure.where(parent_object_oid: parent_oid, source: source))
  end

  # The posted tree is authoritative for presence, so a Preservica row the user dropped goes too.
  def prune_structures_for_editor_save(parent_oid, manifest)
    kept = Structure.preservica_built
                    .where(parent_object_oid: parent_oid, resource_id: posted_resource_ids(manifest))
    prune_structures_for_parent(parent_oid, kept.select(:id))
  end

  def prune_structures_for_parent(parent_oid, kept_ids)
    remove_structures(parent_oid, Structure.where(parent_object_oid: parent_oid).where.not(id: kept_ids))
  end

  def posted_resource_ids(manifest, ids = [])
    (manifest['structures'] || manifest['items'] || []).each do |node|
      ids << (node['type'] == 'Range' ? uuid_from_uri(node['id']) : node['id'])
      posted_resource_ids(node, ids)
    end
    ids
  end

  private

  def remove_structures(parent_oid, removable)
    # dependent: :destroy would take the other flow's rows down with the range they are filed under
    Structure.where(parent_object_oid: parent_oid, structure_id: removable.select(:id))
             .where.not(id: removable.select(:id))
             .update_all(structure_id: nil) # rubocop:disable Rails/SkipsModelValidations
    removable.destroy_all
  end
end
