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

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def parse_range(parent, range, position)
    raise 'Not a Range' unless range['type'] == 'Range'

    uri = range['id']
    id = uuid_from_uri(uri)
    reused = reuse_preservica_range(parent.oid, id, position)
    return reused if reused

    destroy_existing_structure(id, parent.oid)
    result = StructureRange.create!(
      resource_id: id,
      label: range&.[]('label')&.[]('en')&.[](0) || range['label'].to_s,
      position: position,
      parent_object_oid: parent.oid,
      source: Structure::EDITOR
    )
    items = range['items']

    items.each_with_index do |item, index|
      if item['type'] == 'Range'
        result.structures << parse_range(parent, item, index)
      elsif item['type'] == 'Canvas'
        result.structures << parse_canvas(parent, item, index)
      else
        raise 'Unexpected type for item in Range'
      end
    end
    result.save!
    result
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

  def parse_canvas(parent, item, position)
    child_id = child_id_from_uri(item['id'], parent.id)
    child = ChildObject.find(child_id)
    StructureCanvas.create!(
      resource_id: item['id'],
      label: child.label,
      position: position,
      parent_object_oid: parent.oid,
      child_object_oid: child.oid,
      source: Structure::EDITOR
    )
  end

  # Preservica owns a range's label and canvases; the editor only gets to say where it sits.
  def reuse_preservica_range(parent_oid, resource_id, position)
    range = StructureRange.preservica_built.find_by(parent_object_oid: parent_oid, resource_id: resource_id)
    range&.update!(position: position)
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
    remove_structures(parent_oid, Structure.where(parent_object_oid: parent_oid).where.not(id: kept.select(:id)))
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
